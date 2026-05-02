{
  inputs,
  lib,
  self,
  ...
}: {
  perSystem = {
    self',
    pkgs,
    system,
    inputs',
    ...
  }: {
    formatter = pkgs.alejandra;

    packages = let
      burpSuiteProPath = ../../packages/burp-suite-pro;
      burpSuiteProAvailable =
        pkgs.stdenv.isLinux
        && builtins.pathExists (burpSuiteProPath + /default.nix)
        && builtins.pathExists (burpSuiteProPath + /loader.jar);
      nhExe = lib.getExe pkgs.nh;
      activate = pkgs.writeShellApplication {
        name = "activate";
        meta = {
          description = "Activate NixOS with nh and home-manager configurations";
          mainProgram = "activate";
        };
        runtimeInputs =
          [
            pkgs.coreutils
            pkgs.hostname
            pkgs.nix
            pkgs.openssh
          ]
          ++ lib.optionals pkgs.stdenv.isLinux [pkgs.nh];
        text = ''
          set -euo pipefail

          original_args=("$@")
          ref="localhost"
          have_ref=0
          dry_run=0

          while [ "$#" -gt 0 ]; do
            case "$1" in
              --dry-run)
                dry_run=1
                ;;
              -*)
                echo "unsupported activate option: $1" >&2
                exit 2
                ;;
              *)
                if [ "$have_ref" -eq 1 ]; then
                  echo "activate accepts at most one target ref" >&2
                  printf 'received:' >&2
                  printf ' %q' "''${original_args[@]}" >&2
                  printf '\n' >&2
                  exit 2
                fi
                ref="$1"
                have_ref=1
                ;;
            esac
            shift
          done

          flake_ref="${self}"
          home_flake_ref="path:$flake_ref"
          current_host="$(hostname -s)"

          activate_home() {
            local user="$1"
            local host="$2"
            local name="$user"

            if [ -n "$host" ] && [ "$host" != "localhost" ] && [ "$host" != "$current_host" ]; then
              name="$user@$host"
              remote_args=("$name")
              if [ "$dry_run" -eq 1 ]; then
                remote_args+=(--dry-run)
              fi
              nix --extra-experimental-features "nix-command flakes" copy "$flake_ref" --to "ssh-ng://$name"
              exec ssh -t "$name" nix --extra-experimental-features "nix-command flakes" run "$flake_ref#activate" -- "''${remote_args[@]}"
            fi

            extra_args=()
            if [ "$dry_run" -eq 1 ]; then
              extra_args+=(--dry)
            fi

            exec ${nhExe} home switch "''${extra_args[@]}" -b "nixos.$(date '+%Y-%m-%d-%H:%M:%S').bak" -c "$user" "$home_flake_ref"
          }

          activate_system() {
            local host="$1"
            local dry_args=()

            if [ "$dry_run" -eq 1 ]; then
              dry_args+=(--dry)
            fi

            if [ "$host" = "localhost" ] || [ "$host" = "$current_host" ]; then
              nh_args=(
                ${nhExe}
                os
                switch
                -H "$current_host"
                -R
                "''${dry_args[@]}"
                "$flake_ref"
              )
              exec sudo "''${nh_args[@]}"
            fi

            remote_args=("$host")
            if [ "$dry_run" -eq 1 ]; then
              remote_args+=(--dry-run)
            fi
            nix --extra-experimental-features "nix-command flakes" copy "$flake_ref" --to "ssh-ng://$host"
            exec ssh -t "$host" nix --extra-experimental-features "nix-command flakes" run "$flake_ref#activate" -- "''${remote_args[@]}"
          }

          case "$ref" in
            *@*)
              user="''${ref%@*}"
              host="''${ref#*@}"
              activate_home "$user" "$host"
              ;;
            *)
              activate_system "$ref"
              ;;
          esac
        '';
      };
      update = pkgs.writeShellApplication {
        name = "update-main-flake-inputs";
        meta.description = "Update the primary flake inputs";
        text = ''
          nix flake update nixpkgs home-manager
        '';
      };
    in
      {
        inherit activate update;

        default = self'.packages.activate;

        codex = pkgs.callPackage "${self}/packages/codex" {};
        graphrag = pkgs.callPackage "${self}/packages/graphrag" {};
        skills-ref = pkgs.callPackage "${self}/packages/skills-ref" {};
      }
      // lib.optionalAttrs burpSuiteProAvailable {
        burp-suite-pro = pkgs.callPackage burpSuiteProPath {};
      };

    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;

      config.allowUnfree = true;
    };
  };
}
