#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 -p nix
import json
import subprocess
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

UPSTREAM_MANIFEST = "https://releases.gitpod.io/cli/stable/manifest.json"

# Restrict to platforms we actually build for. Upstream also ships windows-*;
# add entries here if you need them.
PLATFORMS = (
    "linux-amd64",
    "linux-arm64",
    "darwin-amd64",
    "darwin-arm64",
)


def main() -> int:
    try:
        run()
    except Exception as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


def run() -> None:
    manifest_file = locate_manifest_file()
    current = json.loads(manifest_file.read_text())
    current_version = current.get("version", "<unknown>")

    upstream = fetch_json(UPSTREAM_MANIFEST)
    version = upstream.get("version")
    if not version:
        raise RuntimeError("upstream manifest is missing 'version'")

    print(f"current version: {current_version}")
    print(f"latest version:  {version}")

    downloads = upstream.get("downloads") or {}
    missing = [p for p in PLATFORMS if p not in downloads]
    if missing:
        raise RuntimeError(
            f"upstream manifest {version} is missing platforms: {', '.join(missing)}; "
            f"available: {', '.join(sorted(downloads))}"
        )

    urls = {p: downloads[p]["url"] for p in PLATFORMS}

    with ThreadPoolExecutor(max_workers=len(PLATFORMS)) as ex:
        checksums = dict(
            zip(
                PLATFORMS,
                ex.map(lambda p: prefetch(urls[p]), PLATFORMS),
                strict=True,
            )
        )

    new_manifest = {
        "version": version,
        "platforms": {p: {"checksum": checksums[p]} for p in PLATFORMS},
    }

    serialized = json.dumps(new_manifest, indent=2) + "\n"
    if serialized == manifest_file.read_text():
        print(f"{manifest_file} is already up to date.")
        return

    manifest_file.write_text(serialized)
    print(f"updated {manifest_file}")


def fetch_json(url: str) -> dict:
    # nosemgrep: python.lang.security.audit.dynamic-urllib-use-detected.dynamic-urllib-use-detected
    with urllib.request.urlopen(url, timeout=30) as response:
        return json.load(response)


def prefetch(url: str) -> str:
    print(f"prefetching {url}")
    result = subprocess.run(
        ["nix-prefetch-url", "--type", "sha256", url],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.stderr:
        sys.stderr.write(result.stderr)
    if result.returncode != 0:
        raise RuntimeError(f"nix-prefetch-url failed for {url}")

    hash_value = result.stdout.strip()
    if not hash_value:
        raise RuntimeError(f"nix-prefetch-url returned an empty hash for {url}")
    return hash_value


def locate_manifest_file() -> Path:
    return Path(sys.argv[0]).resolve().parent / "manifest.json"


if __name__ == "__main__":
    sys.exit(main())
