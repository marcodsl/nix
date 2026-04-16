# Default command when 'just' is run without arguments
default:
    @just --list

# Update nix flake
[group('main')]
update input="":
    #!/usr/bin/env bash
    if [ -z "{{ input }}" ]; then
        nix flake update nixpkgs
    elif [ "{{ input }}" = "all" ]; then
        nix flake update
    else
        nix flake update {{ input }}
    fi

# Format Nix files in place
[group('dev')]
fmt:
    nix fmt -- flake.nix configurations/ modules/ packages/

# Check Nix file formatting without writing changes
[group('dev')]
lint:
    nix fmt -- --check flake.nix configurations/ modules/ packages/

# Check nix flake
[group('dev')]
check:
    nix flake check --no-pure-eval

# Manually enter dev shell
[group('dev')]
dev:
    nix develop --no-pure-eval

# Activate the current NixOS host
[group('main')]
run:
    #!/usr/bin/env bash
    sudo /run/current-system/sw/bin/activate-local-system
