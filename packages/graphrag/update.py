#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3
import base64
import hashlib
import json
import re
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

PYPI_BASE = "https://pypi.org/pypi"

SUB_PACKAGES = [
    "graphrag-common",
    "graphrag-storage",
    "graphrag-cache",
    "graphrag-chunking",
    "graphrag-input",
    "graphrag-llm",
    "graphrag-vectors",
]

ALL_PACKAGES = ["graphrag", *SUB_PACKAGES]


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

    version = latest_pypi_version("graphrag")
    print(f"current version: {current_version}")
    print(f"latest version:  {version}")

    with ThreadPoolExecutor(max_workers=8) as ex:
        sub_versions = dict(
            zip(SUB_PACKAGES, ex.map(latest_pypi_version, SUB_PACKAGES), strict=False)
        )
        for pkg, sub_version in sub_versions.items():
            if sub_version != version:
                raise RuntimeError(
                    f"sub-package {pkg} latest is {sub_version}, expected {version}"
                )

        wheel_infos = dict(
            zip(
                ALL_PACKAGES,
                ex.map(lambda p: fetch_wheel_info(p, version), ALL_PACKAGES),
                strict=False,
            )
        )

    for pkg, info in wheel_infos.items():
        print(f"{pkg}: {info['url']}")

    updated = update_default_nix(current, version, wheel_infos)
    if updated == current:
        print(f"{package_file} is already up to date.")
        return

    package_file.write_text(updated)
    print(f"updated {package_file}")


def latest_pypi_version(package_name: str) -> str:
    data = fetch_json(f"{PYPI_BASE}/{package_name}/json")
    version = data.get("info", {}).get("version")
    if not version:
        raise RuntimeError(
            f"failed to find version in PyPI metadata for {package_name}"
        )
    return version


def fetch_wheel_info(package_name: str, version: str) -> dict[str, str]:
    data = fetch_json(f"{PYPI_BASE}/{package_name}/{version}/json")
    wheel_filename = f"{package_name.replace('-', '_')}-{version}-py3-none-any.whl"

    for entry in data.get("urls", []):
        if entry.get("filename") == wheel_filename:
            url = entry["url"]
            return {"url": url, "hash": fetch_sri_hash(url)}

    raise RuntimeError(
        f"failed to find wheel URL for {package_name} {version} in PyPI response"
    )


def fetch_json(url: str) -> dict:
    with urllib.request.urlopen(url) as response:
        return json.load(response)


def fetch_sri_hash(url: str) -> str:
    print(f"hashing {url}")
    h = hashlib.sha256()
    with urllib.request.urlopen(url) as response:
        for chunk in iter(lambda: response.read(65536), b""):
            h.update(chunk)
    return f"sha256-{base64.b64encode(h.digest()).decode()}"


def extract_nix_version(text: str) -> str:
    for line in text.splitlines():
        trimmed = line.strip()
        if trimmed.startswith('version = "') and trimmed.endswith('";'):
            return trimmed[len('version = "') : -len('";')]
    raise RuntimeError("failed to find version assignment in default.nix")


def update_default_nix(
    text: str,
    version: str,
    wheel_infos: dict[str, dict[str, str]],
) -> str:
    result = sub_once(
        text,
        r'^(\s*version = ")[^"]+(";)',
        rf"\g<1>{version}\g<2>",
        flags=re.MULTILINE,
    )
    for pkg, info in wheel_infos.items():
        pattern = (
            rf'(pname = "{re.escape(pkg)}";.*?url = ")[^"]+'
            rf'(";.*?hash = ")[^"]+(";)'
        )
        replacement = rf"\g<1>{info['url']}\g<2>{info['hash']}\g<3>"
        result = sub_once(result, pattern, replacement, flags=re.DOTALL)

    ensure_contains(result, f'version = "{version}";')
    ensure_contains(result, wheel_infos["graphrag"]["hash"])
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
    for candidate in [cwd / "packages/graphrag/default.nix", cwd / "default.nix"]:
        if candidate.exists():
            return candidate

    raise RuntimeError(
        f"failed to locate default.nix from script path {sys.argv[0]!r} "
        f"or current directory {cwd}"
    )


if __name__ == "__main__":
    sys.exit(main())
