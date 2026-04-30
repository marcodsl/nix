#!/usr/bin/env nix-shell
/*
#!nix-shell -i rust-script -p rustc -p rust-script -p cargo -p curl -p nix
*/

use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

const PYPI_BASE: &str = "https://pypi.org/pypi";

const SUB_PACKAGES: [&str; 7] = [
    "graphrag_common",
    "graphrag_storage",
    "graphrag_cache",
    "graphrag_chunking",
    "graphrag_input",
    "graphrag_llm",
    "graphrag_vectors",
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

    let version = latest_pypi_version("graphrag")?;
    println!("current version: {current_version}");
    println!("latest version:  {version}");

    // Verify all sub-packages are at the same version
    for pkg in &SUB_PACKAGES {
        let pkg_name = pkg.replace('_', "-");
        let sub_version = latest_pypi_version(&pkg_name)?;
        if sub_version != version {
            return Err(format!(
                "sub-package {pkg_name} latest is {sub_version}, expected {version}"
            ));
        }
    }

    // Fetch wheel URLs and hashes for all packages
    let graphrag_info = fetch_wheel_info("graphrag", &version)?;
    println!("graphrag: {}", graphrag_info.url);

    let mut sub_infos = Vec::new();
    for pkg in &SUB_PACKAGES {
        let pkg_name = pkg.replace('_', "-");
        let info = fetch_wheel_info(&pkg_name, &version)?;
        println!("{pkg_name}: {}", info.url);
        sub_infos.push((pkg.to_string(), info));
    }

    let updated = update_default_nix(&current, &version, &graphrag_info, &sub_infos)?;
    if updated == current {
        println!("{} is already up to date.", package_file.display());
        return Ok(());
    }

    fs::write(&package_file, updated)
        .map_err(|error| format!("failed to write {}: {error}", package_file.display()))?;
    println!("updated {}", package_file.display());

    Ok(())
}

struct WheelInfo {
    url: String,
    hash: String,
}

fn read_package_file(package_file: &Path) -> Result<String, String> {
    fs::read_to_string(package_file)
        .map_err(|error| format!("failed to read {}: {error}", package_file.display()))
}

fn latest_pypi_version(package_name: &str) -> Result<String, String> {
    let url = format!("{PYPI_BASE}/{package_name}/json");
    let json = fetch(&url)?;
    json_string(&json, "version")
        .ok_or_else(|| format!("failed to find version in PyPI metadata for {package_name}"))
}

fn fetch_wheel_info(package_name: &str, version: &str) -> Result<WheelInfo, String> {
    let url = format!("{PYPI_BASE}/{package_name}/{version}/json");
    let json = fetch(&url)?;

    let wheel_url = find_wheel_url(&json, package_name, version)?;
    println!("prefetching {wheel_url}");
    let hash = prefetch(&wheel_url)?;

    Ok(WheelInfo {
        url: wheel_url,
        hash,
    })
}

fn find_wheel_url(json: &str, package_name: &str, version: &str) -> Result<String, String> {
    let filename_fragment = format!(
        "\"filename\": \"{}-{}-py3-none-any.whl\"",
        package_name.replace('-', "_"),
        version
    );

    if let Some(idx) = json.find(&filename_fragment) {
        let before = &json[..idx];
        if let Some(url_start) = before.rfind("\"url\": \"") {
            let after_url = &json[url_start + 8..];
            if let Some(url_end) = after_url.find('"') {
                return Ok(after_url[..url_end].to_string());
            }
        }
    }

    Err(format!(
        "failed to find wheel URL for {package_name} {version} in PyPI response"
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
        hash.replace_range(.."sha256-".len(), "");
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
    graphrag_info: &WheelInfo,
    sub_infos: &[(String, WheelInfo)],
) -> Result<String, String> {
    let mut output = String::new();
    let mut current_section = String::new();
    let mut version_replaced = false;

    for line in input.lines() {
        let trimmed = line.trim();

        // Track which sub-package section we're in by looking at the derivation name
        if trimmed.starts_with("graphrag-common = ") {
            current_section = "graphrag_common".to_string();
        } else if trimmed.starts_with("graphrag-storage = ") {
            current_section = "graphrag_storage".to_string();
        } else if trimmed.starts_with("graphrag-cache = ") {
            current_section = "graphrag_cache".to_string();
        } else if trimmed.starts_with("graphrag-chunking = ") {
            current_section = "graphrag_chunking".to_string();
        } else if trimmed.starts_with("graphrag-input = ") {
            current_section = "graphrag_input".to_string();
        } else if trimmed.starts_with("graphrag-llm = ") {
            current_section = "graphrag_llm".to_string();
        } else if trimmed.starts_with("graphrag-vectors = ") {
            current_section = "graphrag_vectors".to_string();
        } else if trimmed.starts_with("python3Packages.buildPythonApplication") {
            current_section = "graphrag".to_string();
        }

        // Only replace the top-level version; dependencies may have their own pins.
        if !version_replaced && trimmed.starts_with("version = \"") {
            let indent: String = line.chars().take_while(|c| c.is_whitespace()).collect();
            output.push_str(&format!("{indent}version = \"{version}\";"));
            output.push('\n');
            version_replaced = true;
            continue;
        }

        // Replace URL lines
        if trimmed.starts_with("url = \"https://files.pythonhosted.org/") {
            let indent: String = line.chars().take_while(|c| c.is_whitespace()).collect();
            if let Some(new_url) = if current_section == "graphrag" {
                Some(&graphrag_info.url)
            } else if let Some((_, info)) =
                sub_infos.iter().find(|(name, _)| *name == current_section)
            {
                Some(&info.url)
            } else {
                None
            } {
                output.push_str(&format!("{indent}url = \"{new_url}\";"));
                output.push('\n');
                continue;
            }
        }

        // Replace hash lines
        if trimmed.starts_with("hash = \"sha256-") {
            let indent: String = line.chars().take_while(|c| c.is_whitespace()).collect();
            if let Some(new_hash) = if current_section == "graphrag" {
                Some(&graphrag_info.hash)
            } else if let Some((_, info)) =
                sub_infos.iter().find(|(name, _)| *name == current_section)
            {
                Some(&info.hash)
            } else {
                None
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
    ensure_contains(&output, &graphrag_info.hash)?;

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
        cwd.join("packages/graphrag/default.nix"),
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
