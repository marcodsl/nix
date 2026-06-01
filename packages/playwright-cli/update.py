#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 -p nix -p prefetch-npm-deps -p gnutar -p gzip
import json
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

REPO = "microsoft/playwright-cli"
GITHUB_LATEST_RELEASE = f"https://api.github.com/repos/{REPO}/releases/latest"
GITHUB_TAGS = f"https://api.github.com/repos/{REPO}/tags?per_page=100"
USER_AGENT = "nixos-config-playwright-cli-updater"


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

    tag, version, rev = latest_tag_and_rev()
    print(f"current version: {current_version}")
    print(f"latest version:  {version} (tag {tag}, rev {rev})")

    if version == current_version:
        print(f"{package_file} is already up to date.")
        return

    tarball_url = f"https://github.com/{REPO}/archive/{rev}.tar.gz"
    src_hash = prefetch_src_sri(tarball_url)
    npm_deps_hash = compute_npm_deps_hash(tarball_url)

    updated = update_default_nix(current, version, rev, src_hash, npm_deps_hash)
    if updated == current:
        print(f"{package_file} is already up to date.")
        return

    package_file.write_text(updated)
    print(f"updated {package_file}")

    verify_build()


def latest_tag_and_rev() -> tuple[str, str, str]:
    try:
        release = fetch_json(GITHUB_LATEST_RELEASE)
        tag = release.get("tag_name")
        if not tag:
            raise RuntimeError("releases/latest has no tag_name")
    except urllib.error.HTTPError as error:
        if error.code != 404:
            raise
        tag = highest_semver_tag()

    version = tag.lstrip("v")
    rev = resolve_tag_to_sha(tag)
    return tag, version, rev


def highest_semver_tag() -> str:
    tags = fetch_json(GITHUB_TAGS)
    parsed: list[tuple[tuple[int, ...], str]] = []
    for entry in tags:
        name = entry.get("name", "")
        match = re.fullmatch(r"v(\d+)\.(\d+)\.(\d+)", name)
        if not match:
            continue
        parsed.append((tuple(int(g) for g in match.groups()), name))
    if not parsed:
        raise RuntimeError("no semver tags found on upstream")
    parsed.sort()
    return parsed[-1][1]


def resolve_tag_to_sha(tag: str) -> str:
    data = fetch_json(f"https://api.github.com/repos/{REPO}/git/ref/tags/{tag}")
    obj = data.get("object", {})
    sha = obj.get("sha")
    if not sha:
        raise RuntimeError(f"could not resolve tag {tag!r} to a SHA")
    if obj.get("type") == "tag":
        # Annotated tag; dereference to the commit.
        tag_obj = fetch_json(f"https://api.github.com/repos/{REPO}/git/tags/{sha}")
        target = tag_obj.get("object", {}).get("sha")
        if not target:
            raise RuntimeError(f"annotated tag {tag!r} has no target SHA")
        return target
    return sha


def prefetch_src_sri(url: str) -> str:
    print(f"prefetching {url}")
    result = subprocess.run(
        ["nix-prefetch-url", "--unpack", "--type", "sha256", url],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.stderr:
        sys.stderr.write(result.stderr)
    if result.returncode != 0:
        raise RuntimeError(f"nix-prefetch-url failed for {url}")
    raw = result.stdout.strip()
    if not raw:
        raise RuntimeError(f"nix-prefetch-url returned an empty hash for {url}")
    return to_sri(raw)


def to_sri(base32_hash: str) -> str:
    result = subprocess.run(
        ["nix-hash", "--to-sri", "--type", "sha256", base32_hash],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        sys.stderr.write(result.stderr)
        raise RuntimeError(f"nix-hash --to-sri failed for {base32_hash}")
    sri = result.stdout.strip()
    if not sri.startswith("sha256-"):
        raise RuntimeError(f"unexpected SRI output: {sri!r}")
    return sri


def compute_npm_deps_hash(tarball_url: str) -> str:
    print(f"computing npmDepsHash from {tarball_url}")
    with tempfile.TemporaryDirectory(prefix="playwright-cli-update-") as tmp:
        tmp_path = Path(tmp)
        tarball = tmp_path / "src.tar.gz"
        download(tarball_url, tarball)

        with tarfile.open(tarball, "r:gz") as tar:
            tar.extractall(tmp_path)

        roots = [p for p in tmp_path.iterdir() if p.is_dir()]
        if len(roots) != 1:
            raise RuntimeError(f"expected one top-level dir in tarball, got {roots}")
        root = roots[0]
        lockfile = root / "package-lock.json"
        if not lockfile.is_file():
            raise RuntimeError(f"package-lock.json missing under {root}")

        result = subprocess.run(
            ["prefetch-npm-deps", str(lockfile)],
            check=False,
            capture_output=True,
            text=True,
        )
        if result.stderr:
            sys.stderr.write(result.stderr)
        if result.returncode != 0:
            raise RuntimeError("prefetch-npm-deps failed")
        sri = result.stdout.strip()
        if not sri.startswith("sha256-"):
            raise RuntimeError(f"prefetch-npm-deps returned unexpected output: {sri!r}")
        return sri


def download(url: str, dest: Path) -> None:
    if not url.startswith("https://"):
        raise ValueError(f"refusing to fetch non-https URL: {url!r}")
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    # nosemgrep: python.lang.security.audit.dynamic-urllib-use-detected.dynamic-urllib-use-detected
    with urllib.request.urlopen(request, timeout=60) as response, dest.open("wb") as fh:
        shutil.copyfileobj(response, fh)


def fetch_json(url: str) -> Any:
    if not url.startswith("https://"):
        raise ValueError(f"refusing to fetch non-https URL: {url!r}")
    request = urllib.request.Request(
        url,
        headers={"User-Agent": USER_AGENT, "Accept": "application/vnd.github+json"},
    )
    # nosemgrep: python.lang.security.audit.dynamic-urllib-use-detected.dynamic-urllib-use-detected
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def extract_nix_version(text: str) -> str:
    for line in text.splitlines():
        trimmed = line.strip()
        if trimmed.startswith('version = "') and trimmed.endswith('";'):
            return trimmed[len('version = "') : -len('";')]
    raise RuntimeError("failed to find version assignment in default.nix")


def update_default_nix(
    text: str,
    version: str,
    rev: str,
    src_hash: str,
    npm_deps_hash: str,
) -> str:
    result = sub_once(
        text,
        r'^(\s*version = ")[^"]+(";)',
        rf"\g<1>{version}\g<2>",
        flags=re.MULTILINE,
    )
    result = sub_once(
        result,
        r'(fetchFromGitHub\s*\{[^}]*?\brev = ")[^"]+(";)',
        rf"\g<1>{rev}\g<2>",
        flags=re.DOTALL,
    )
    result = sub_once(
        result,
        r'(fetchFromGitHub\s*\{[^}]*?\bhash = ")[^"]+(";)',
        rf"\g<1>{src_hash}\g<2>",
        flags=re.DOTALL,
    )
    result = sub_once(
        result,
        r'^(\s*npmDepsHash = ")[^"]+(";)',
        rf"\g<1>{npm_deps_hash}\g<2>",
        flags=re.MULTILINE,
    )

    ensure_contains(result, f'version = "{version}";')
    ensure_contains(result, f'rev = "{rev}";')
    ensure_contains(result, f'hash = "{src_hash}";')
    ensure_contains(result, f'npmDepsHash = "{npm_deps_hash}";')
    return result


def sub_once(text: str, pattern: str, replacement: str, flags: int = 0) -> str:
    new_text, count = re.subn(pattern, replacement, text, count=1, flags=flags)
    if count == 0:
        raise RuntimeError(f"failed to find pattern in default.nix: {pattern}")
    return new_text


def ensure_contains(text: str, needle: str) -> None:
    if needle not in text:
        raise RuntimeError(f"updated default.nix is missing expected text: {needle}")


def verify_build() -> None:
    flake_root = locate_flake_root()
    print(f"verifying with nix build .#playwright-cli (cwd={flake_root})")
    result = subprocess.run(
        [
            "nix",
            "build",
            ".#playwright-cli",
            "--no-pure-eval",
            "--no-link",
            "--print-build-logs",
        ],
        cwd=flake_root,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError("nix build .#playwright-cli failed after updating pins")


def locate_package_file() -> Path:
    script = Path(sys.argv[0]).resolve()
    candidate = script.parent / "default.nix"
    if candidate.exists():
        return candidate
    raise RuntimeError(f"failed to locate default.nix next to {script}")


def locate_flake_root() -> Path:
    # packages/playwright-cli/update.py → repo root is two parents up.
    return Path(sys.argv[0]).resolve().parents[2]


if __name__ == "__main__":
    sys.exit(main())
