#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 -p nix
import json
import subprocess
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

NPM_LATEST = "https://registry.npmjs.org/@anthropic-ai/claude-code/latest"
BASE_URL = (
    "https://storage.googleapis.com/"
    "claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"
)
NPM_PLATFORM_PREFIX = "@anthropic-ai/claude-code-"

# Restrict the manifest to platforms we actually build for. Anthropic publishes
# more (musl, win32, …); add entries here if you need them.
PLATFORMS = (
    "linux-x64",
    "linux-arm64",
    "darwin-x64",
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

    npm_meta = fetch_json(NPM_LATEST)
    version = npm_meta.get("version")
    if not version:
        raise RuntimeError("npm metadata is missing 'version'")

    print(f"current version: {current_version}")
    print(f"latest version:  {version}")

    available = npm_platforms(npm_meta)
    missing = [p for p in PLATFORMS if p not in available]
    if missing:
        raise RuntimeError(
            f"npm release {version} does not ship platforms: {', '.join(missing)}; "
            f"available: {', '.join(sorted(available))}"
        )

    with ThreadPoolExecutor(max_workers=len(PLATFORMS)) as ex:
        checksums = dict(
            zip(
                PLATFORMS,
                ex.map(lambda p: prefetch(binary_url(version, p)), PLATFORMS),
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


def npm_platforms(npm_meta: dict) -> set[str]:
    deps = npm_meta.get("optionalDependencies") or {}
    return {
        name[len(NPM_PLATFORM_PREFIX) :]
        for name in deps
        if name.startswith(NPM_PLATFORM_PREFIX)
    }


def binary_url(version: str, platform: str) -> str:
    return f"{BASE_URL}/{version}/{platform}/claude"


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
