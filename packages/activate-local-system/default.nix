{
  coreutils,
  hostname,
  hostName ? null,
  repoRoot ? null,
  writeShellApplication,
}:
writeShellApplication {
  name = "activate-local-system";
  runtimeInputs = [
    coreutils
    hostname
  ];
  text = ''
    set -euo pipefail

    expected_root=${builtins.toJSON repoRoot}
    current_root="$(pwd -P)"
    target_host=${builtins.toJSON hostName}

    if [ -z "$expected_root" ]; then
      expected_root="$current_root"
    fi

    if [ -z "$target_host" ]; then
      target_host="$(hostname -s)"
    fi

    if [ "$current_root" != "$expected_root" ]; then
      echo "activate-local-system must be run from $expected_root" >&2
      exit 1
    fi

    exec /run/current-system/sw/bin/nixos-rebuild switch --flake "$expected_root#$target_host"
  '';
}
