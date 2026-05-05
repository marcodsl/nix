#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 -p nix
import json
import re
import subprocess
import sys
import urllib.request
from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

GITHUB_LATEST_RELEASE = "https://api.github.com/repos/openai/codex/releases/latest"
NPM_LATEST = "https://registry.npmjs.org/@openai/codex/latest"

NATIVE_PLATFORMS = [
    "aarch64-apple-darwin",
    "x86_64-unknown-linux-musl",
    "aarch64-unknown-linux-musl",
]

NODE_PLATFORMS = ["darwin-arm64", "linux-x64", "linux-arm64"]


def main() -> int:
    try:
        run()
    except Exception as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


def run() -> None:
    package_file = locate_package_file()
    current = package_file.read_text()
    current_version = extract_nix_version(current)

    version = latest_release_version()
    ensure_matching_npm_version(version)

    print(f"current version: {current_version}")
    print(f"latest version:  {version}")

    with ThreadPoolExecutor(max_workers=8) as ex:
        native_hashes_future = ex.submit(
            collect_hashes,
            NATIVE_PLATFORMS,
            lambda p: native_release_url(version, p),
            ex,
        )
        npm_hash_future = ex.submit(prefetch, npm_tarball_url(version))
        node_hashes_future = ex.submit(
            collect_hashes, NODE_PLATFORMS, lambda p: node_release_url(version, p), ex
        )
        native_hashes = native_hashes_future.result()
        npm_hash = npm_hash_future.result()
        node_hashes = node_hashes_future.result()

    updated = update_default_nix(current, version, native_hashes, npm_hash, node_hashes)
    if updated == current:
        print(f"{package_file} is already up to date.")
        return

    package_file.write_text(updated)
    print(f"updated {package_file}")


def latest_release_version() -> str:
    data = fetch_json(GITHUB_LATEST_RELEASE)
    tag = data.get("tag_name")
    if not tag:
        raise RuntimeError("failed to find tag_name in GitHub release")
    if not tag.startswith("rust-v"):
        raise RuntimeError(
            f"unexpected GitHub release tag {tag!r}; expected rust-v<version>"
        )
    return tag[len("rust-v") :]


def ensure_matching_npm_version(version: str) -> None:
    data = fetch_json(NPM_LATEST)
    npm_version = data.get("version")
    if not npm_version:
        raise RuntimeError("failed to find version in npm metadata")
    if npm_version != version:
        raise RuntimeError(
            f"GitHub latest release is {version}, but npm latest is {npm_version}; "
            "refusing to update mixed artifacts"
        )


def collect_hashes(
    platforms: list[str],
    url_for: Callable[[str], str],
    executor: ThreadPoolExecutor,
) -> dict[str, str]:
    urls = [url_for(p) for p in platforms]
    return dict(zip(platforms, executor.map(prefetch, urls), strict=False))


def native_release_url(version: str, platform: str) -> str:
    return (
        "https://github.com/openai/codex/releases/download/"
        f"rust-v{version}/codex-{platform}.tar.gz"
    )


def npm_tarball_url(version: str) -> str:
    return f"https://registry.npmjs.org/@openai/codex/-/codex-{version}.tgz"


def node_release_url(version: str, platform: str) -> str:
    return (
        "https://github.com/openai/codex/releases/download/"
        f"rust-v{version}/codex-npm-{platform}-{version}.tgz"
    )


def fetch_json(url: str) -> dict:
    with urllib.request.urlopen(url) as response:
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


def extract_nix_version(text: str) -> str:
    for line in text.splitlines():
        trimmed = line.strip()
        if trimmed.startswith('version = "') and trimmed.endswith('";'):
            return trimmed[len('version = "') : -len('";')]
    raise RuntimeError("failed to find version assignment in default.nix")


def update_default_nix(
    text: str,
    version: str,
    native_hashes: dict[str, str],
    npm_hash: str,
    node_hashes: dict[str, str],
) -> str:
    result = sub_once(
        text,
        r'^(\s*version = ")[^"]+(";)',
        rf"\g<1>{version}\g<2>",
        flags=re.MULTILINE,
    )
    result = sub_once(
        result,
        r'(npmTarball =.*?sha256 = ")[^"]+(";)',
        rf"\g<1>{npm_hash}\g<2>",
        flags=re.DOTALL,
    )
    for platform, hash_value in {**native_hashes, **node_hashes}.items():
        result = sub_once(
            result,
            rf'(\s"{re.escape(platform)}" = ")[^"]+(";)',
            rf"\g<1>{hash_value}\g<2>",
        )

    ensure_contains(result, f'version = "{version}";')
    ensure_contains(result, f'sha256 = "{npm_hash}";')
    return result


def sub_once(text: str, pattern: str, replacement: str, flags: int = 0) -> str:
    new_text, count = re.subn(pattern, replacement, text, count=1, flags=flags)
    if count == 0:
        raise RuntimeError(f"failed to find pattern in default.nix: {pattern}")
    return new_text


def ensure_contains(text: str, needle: str) -> None:
    if needle not in text:
        raise RuntimeError(f"updated default.nix is missing expected text: {needle}")


def locate_package_file() -> Path:
    script = Path(sys.argv[0])
    candidate = script.parent / "default.nix"
    if candidate.exists():
        return candidate

    cwd = Path.cwd()
    for candidate in [cwd / "packages/codex/default.nix", cwd / "default.nix"]:
        if candidate.exists():
            return candidate

    raise RuntimeError(
        f"failed to locate default.nix from script path {sys.argv[0]!r} "
        f"or current directory {cwd}"
    )


if __name__ == "__main__":
    sys.exit(main())
