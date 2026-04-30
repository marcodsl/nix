#!/usr/bin/env nix-shell
/*
#!nix-shell -i rust-script -p rustc -p rust-script -p cargo -p curl -p nix
*/

use std::collections::BTreeMap;
use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

type Hashes = BTreeMap<String, String>;

const GITHUB_LATEST_RELEASE: &str = "https://api.github.com/repos/openai/codex/releases/latest";
const NPM_LATEST: &str = "https://registry.npmjs.org/@openai/codex/latest";

const NATIVE_PLATFORMS: [&str; 4] = [
    "aarch64-apple-darwin",
    "x86_64-apple-darwin",
    "x86_64-unknown-linux-musl",
    "aarch64-unknown-linux-musl",
];

const NODE_PLATFORMS: [&str; 4] = ["darwin-arm64", "darwin-x64", "linux-x64", "linux-arm64"];

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

    let version = latest_release_version()?;
    ensure_matching_npm_version(&version)?;

    println!("current version: {current_version}");
    println!("latest version:  {version}");

    let native_hashes = collect_hashes(&NATIVE_PLATFORMS, |platform| {
        native_release_url(&version, platform)
    })?;

    let npm_hash = prefetch(&npm_tarball_url(&version))?;

    let node_hashes = collect_hashes(&NODE_PLATFORMS, |platform| {
        node_release_url(&version, platform)
    })?;

    let updated = update_default_nix(&current, &version, &native_hashes, &npm_hash, &node_hashes)?;
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

fn latest_release_version() -> Result<String, String> {
    let release_json = fetch(GITHUB_LATEST_RELEASE)?;
    github_release_version(&release_json)
}

fn ensure_matching_npm_version(version: &str) -> Result<(), String> {
    let npm_json = fetch(NPM_LATEST)?;
    let npm_version = json_string(&npm_json, "version")
        .ok_or_else(|| "failed to find version in npm metadata".to_string())?;

    if npm_version == version {
        Ok(())
    } else {
        Err(format!(
            "GitHub latest release is {version}, but npm latest is {npm_version}; refusing to update mixed artifacts"
        ))
    }
}

fn collect_hashes<F>(platforms: &[&str], mut url_for: F) -> Result<Hashes, String>
where
    F: FnMut(&str) -> String,
{
    let mut hashes = BTreeMap::new();
    for platform in platforms {
        let url = url_for(platform);
        hashes.insert((*platform).to_string(), prefetch(&url)?);
    }
    Ok(hashes)
}

fn native_release_url(version: &str, platform: &str) -> String {
    format!(
        "https://github.com/openai/codex/releases/download/rust-v{version}/codex-{platform}.tar.gz"
    )
}

fn npm_tarball_url(version: &str) -> String {
    format!("https://registry.npmjs.org/@openai/codex/-/codex-{version}.tgz")
}

fn node_release_url(version: &str, platform: &str) -> String {
    format!(
        "https://github.com/openai/codex/releases/download/rust-v{version}/codex-npm-{platform}-{version}.tgz"
    )
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
        cwd.join("packages/codex/default.nix"),
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

    Ok(hash)
}

fn github_release_version(json: &str) -> Result<String, String> {
    let tag = json_string(json, "tag_name")
        .ok_or_else(|| "failed to find tag_name in GitHub release".to_string())?;
    tag.strip_prefix("rust-v")
        .ok_or_else(|| format!("unexpected GitHub release tag {tag:?}; expected rust-v<version>"))
        .map(str::to_string)
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
    native_hashes: &Hashes,
    npm_hash: &str,
    node_hashes: &Hashes,
) -> Result<String, String> {
    let mut output = String::new();
    let mut in_npm_tarball = false;

    for line in input.lines() {
        let trimmed = line.trim_start();
        in_npm_tarball = next_npm_tarball_state(in_npm_tarball, trimmed);

        let replacement = replacement_line(
            line,
            trimmed,
            version,
            npm_hash,
            in_npm_tarball,
            native_hashes,
            node_hashes,
        );

        output.push_str(replacement.as_deref().unwrap_or(line));
        output.push('\n');
    }

    ensure_platforms_present(&output, &NATIVE_PLATFORMS)?;
    ensure_platforms_present(&output, &NODE_PLATFORMS)?;
    ensure_contains(&output, &format!("version = \"{version}\";"))?;
    ensure_contains(&output, &format!("sha256 = \"{npm_hash}\";"))?;

    Ok(output)
}

fn next_npm_tarball_state(in_npm_tarball: bool, trimmed: &str) -> bool {
    if trimmed.starts_with("npmTarball =") {
        true
    } else if in_npm_tarball && trimmed.starts_with("nodeOptionalDep =") {
        false
    } else {
        in_npm_tarball
    }
}

fn replacement_line(
    line: &str,
    trimmed: &str,
    version: &str,
    npm_hash: &str,
    in_npm_tarball: bool,
    native_hashes: &Hashes,
    node_hashes: &Hashes,
) -> Option<String> {
    if trimmed.starts_with("version = \"") {
        Some(format!("  version = \"{version}\";"))
    } else if in_npm_tarball && trimmed.starts_with("sha256 = \"") {
        Some(format!("        sha256 = \"{npm_hash}\";"))
    } else {
        replacement_for_hash_line(line, native_hashes)
            .or_else(|| replacement_for_hash_line(line, node_hashes))
    }
}

fn replacement_for_hash_line(line: &str, hashes: &Hashes) -> Option<String> {
    for (platform, hash) in hashes {
        let trimmed_prefix = format!("\"{platform}\" = \"");
        if line.trim_start().starts_with(&trimmed_prefix) {
            return Some(format!("    \"{platform}\" = \"{hash}\";"));
        }
    }
    None
}

fn ensure_platforms_present(input: &str, platforms: &[&str]) -> Result<(), String> {
    for platform in platforms {
        ensure_contains(input, platform)?;
    }
    Ok(())
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
