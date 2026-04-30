#!/usr/bin/env nix-shell
/*
#!nix-shell -i rust-script -p rustc -p rust-script -p cargo -p curl -p nix
*/

use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

const NPM_REGISTRY: &str = "https://registry.npmjs.org";

const DEPENDENCIES: [&str; 3] = [
    "turndown",
    "turndown-plugin-gfm",
    "@mixmark-io/domino",
];

fn main() {
    if let Err(error) = run() {
        eprintln!("error: {error}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let package_file = package_file()?;
    let current = read_package_file(&package_file)?;
    let current_version = extract_nix_version(&current)?;

    let version = latest_npm_version("context-mode")?;
    println!("current version: {current_version}");
    println!("latest version:  {version}");

    let context_mode_hash = prefetch(&npm_tarball_url("context-mode", &version))?;
    println!("context-mode: {}", npm_tarball_url("context-mode", &version));

    let mut dep_hashes = Vec::new();
    for dep in &DEPENDENCIES {
        let dep_version = latest_npm_version(dep)?;
        let url = npm_tarball_url(dep, &dep_version);
        println!("{dep} {dep_version}: {url}");
        let hash = prefetch(&url)?;
        dep_hashes.push((dep.to_string(), dep_version, hash));
    }

    let updated = update_default_nix(&current, &version, &context_mode_hash, &dep_hashes)?;
    if updated == current {
        println!("{} is already up to date.", package_file.display());
        return Ok(());
    }

    fs::write(&package_file, updated)
        .map_err(|error| format!("failed to write {}: {error}", package_file.display()))?;
    println!("updated {}", package_file.display());

    Ok(())
}

fn read_package_file(package_file: &Path) -> Result<String, String> {
    fs::read_to_string(package_file)
        .map_err(|error| format!("failed to read {}: {error}", package_file.display()))
}

fn latest_npm_version(package_name: &str) -> Result<String, String> {
    let url = format!("{NPM_REGISTRY}/{package_name}/latest");
    let json = fetch(&url)?;
    json_string(&json, "version")
        .ok_or_else(|| format!("failed to find version in npm metadata for {package_name}"))
}

fn npm_tarball_url(package_name: &str, version: &str) -> String {
    let escaped = package_name.replace('/', "%2F");
    format!("{NPM_REGISTRY}/{package_name}/-/{escaped}-{version}.tgz")
}

fn fetch(url: &str) -> Result<String, String> {
    let output = Command::new("curl")
        .args(["-fsSL", url])
        .output()
        .map_err(|error| format!("failed to run curl for {url}: {error}"))?;

    if !output.status.success() {
        return Err(format!(
            "curl failed for {url}: {}",
            String::from_utf8_lossy(&output.stderr).trim()
        ));
    }

    String::from_utf8(output.stdout)
        .map_err(|error| format!("curl returned invalid UTF-8 for {url}: {error}"))
}

fn prefetch(url: &str) -> Result<String, String> {
    println!("prefetching {url}");
    let output = Command::new("nix-prefetch-url")
        .args(["--type", "sha256", url])
        .stderr(Stdio::inherit())
        .output()
        .map_err(|error| format!("failed to run nix-prefetch-url for {url}: {error}"))?;

    if !output.status.success() {
        return Err(format!("nix-prefetch-url failed for {url}"));
    }

    let hash = String::from_utf8(output.stdout)
        .map_err(|error| format!("nix-prefetch-url returned invalid UTF-8 for {url}: {error}"))?
        .trim()
        .to_string();
    if hash.is_empty() {
        return Err(format!("nix-prefetch-url returned an empty hash for {url}"));
    }

    Ok(normalize_sha256_hash(hash))
}

/// Removes an existing SRI sha256 prefix so callers can add one consistently.
fn normalize_sha256_hash(mut hash: String) -> String {
    if hash.starts_with("sha256-") {
        hash.replace_range(0.."sha256-".len(), "");
    }
    hash
}

fn json_string(json: &str, key: &str) -> Option<String> {
    let needle = format!("\"{key}\"");
    let key_start = json.find(&needle)?;
    let after_key = &json[key_start + needle.len()..];
    let colon = after_key.find(':')?;
    let after_colon = after_key[colon + 1..].trim_start();
    let mut chars = after_colon.chars();
    if chars.next()? != '"' {
        return None;
    }

    let mut value = String::new();
    let mut escaped = false;
    for ch in chars {
        if escaped {
            value.push(ch);
            escaped = false;
        } else if ch == '\\' {
            escaped = true;
        } else if ch == '"' {
            return Some(value);
        } else {
            value.push(ch);
        }
    }

    None
}

fn extract_nix_version(input: &str) -> Result<String, String> {
    for line in input.lines() {
        let trimmed = line.trim();
        if let Some(rest) = trimmed.strip_prefix("version = \"") {
            if let Some(version) = rest.strip_suffix("\";") {
                return Ok(version.to_string());
            }
        }
    }
    Err("failed to find version assignment in default.nix".to_string())
}

fn update_default_nix(
    input: &str,
    version: &str,
    context_mode_hash: &str,
    dep_hashes: &[(String, String, String)],
) -> Result<String, String> {
    let mut output = String::new();
    let mut current_dep: Option<&str> = None;

    for line in input.lines() {
        let trimmed = line.trim();

        // Track which dependency section we're in
        if trimmed.starts_with("turndownTarball") {
            current_dep = Some("turndown");
        } else if trimmed.starts_with("turndownPluginGfmTarball") {
            current_dep = Some("turndown-plugin-gfm");
        } else if trimmed.starts_with("dominoTarball") {
            current_dep = Some("@mixmark-io/domino");
        } else if trimmed.starts_with("contextModeTarball") {
            current_dep = Some("context-mode");
        }

        // Replace version
        if trimmed.starts_with("version = \"") {
            let indent: String = line.chars().take_while(|c| c.is_whitespace()).collect();
            output.push_str(&format!("{indent}version = \"{version}\";"));
            output.push('\n');
            continue;
        }

        // Replace URL lines
        if trimmed.starts_with("url = \"https://registry.npmjs.org/") {
            let indent: String = line.chars().take_while(|c| c.is_whitespace()).collect();
            if let Some(new_url) = match current_dep {
                Some("context-mode") => Some(npm_tarball_url("context-mode", version)),
                Some(dep) => {
                    if let Some((_, dep_ver, _)) =
                        dep_hashes.iter().find(|(name, _, _)| name == dep)
                    {
                        Some(npm_tarball_url(dep, dep_ver))
                    } else {
                        None
                    }
                }
                None => None,
            } {
                output.push_str(&format!("{indent}url = \"{new_url}\";"));
                output.push('\n');
                continue;
            }
        }

        // Replace hash lines
        if trimmed.starts_with("hash = \"sha256-") {
            let indent: String = line.chars().take_while(|c| c.is_whitespace()).collect();
            if let Some(new_hash) = match current_dep {
                Some("context-mode") => Some(context_mode_hash.to_string()),
                Some(dep) => {
                    if let Some((_, _, hash)) = dep_hashes.iter().find(|(name, _, _)| name == dep) {
                        Some(hash.clone())
                    } else {
                        None
                    }
                }
                None => None,
            } {
                output.push_str(&format!("{indent}hash = \"sha256-{new_hash}\";"));
                output.push('\n');
                continue;
            }
        }

        output.push_str(line);
        output.push('\n');
    }

    ensure_contains(&output, &format!("version = \"{version}\";"))?;
    ensure_contains(&output, context_mode_hash)?;

    Ok(output)
}

fn ensure_contains(input: &str, needle: &str) -> Result<(), String> {
    if input.contains(needle) {
        Ok(())
    } else {
        Err(format!(
            "updated default.nix is missing expected text: {needle}"
        ))
    }
}

fn package_file() -> Result<PathBuf, String> {
    let exe_arg = env::args()
        .next()
        .unwrap_or_else(|| "update.rs".to_string());
    let script = Path::new(&exe_arg);

    if let Some(candidate) = script
        .parent()
        .filter(|parent| *parent != Path::new(""))
        .map(|parent| parent.join("default.nix"))
        .filter(|candidate| candidate.exists())
    {
        return Ok(candidate);
    }

    let cwd =
        env::current_dir().map_err(|error| format!("failed to read current directory: {error}"))?;

    for candidate in [
        cwd.join("packages/context-mode/default.nix"),
        cwd.join("default.nix"),
    ] {
        if candidate.exists() {
            return Ok(candidate);
        }
    }

    Err(format!(
        "failed to locate default.nix from script path {exe_arg:?} or current directory {}",
        cwd.display()
    ))
}
