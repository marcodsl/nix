# Default command when 'just' is run without arguments
default:
    @just --list

# Update nix flake
[group('main')]
update input="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -z "{{ input }}" ]; then
        nix flake update nixpkgs
    elif [ "{{ input }}" = "all" ]; then
        nix flake update
    else
        if [[ "{{ input }}" == *,,* || "{{ input }}" == ,* || "{{ input }}" == *, ]]; then
            echo "Error: empty input segment detected in '{{ input }}'" >&2
            exit 1
        fi
        IFS=',' read -ra args <<< "{{ input }}"
        for arg in "${args[@]}"; do
            if [ "$arg" = "all" ]; then
                echo "Error: 'all' cannot be used in a comma-separated list" >&2
                exit 1
            fi
        done
        nix flake update "${args[@]}"
    fi

# Format Nix files in place
[group('dev')]
fmt:
    nix fmt -- flake.nix hosts/ modules/ packages/ users/

# Check Nix file formatting without writing changes
[group('dev')]
lint:
    nix fmt -- --check flake.nix hosts/ modules/ packages/ users/

# Check nix flake
[group('dev')]
check:
    nix flake check --no-pure-eval

# Manually enter dev shell
[group('dev')]
dev:
    nix develop --no-pure-eval

# Activate the configuration
[group('main')]
run:
    #!/usr/bin/env bash
    nix run .#activate
