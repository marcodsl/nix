{
  perSystem = {
    self',
    pkgs,
    lib,
    ...
  }: {
    apps = {
      activate = {
        inherit (self'.packages.activate) meta;

        program = pkgs.writeShellApplication {
          name = "activate-system";
          runtimeInputs = [pkgs.hostname];
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
                  exec ${lib.getExe self'.packages.activate} "''${original_args[@]}"
                  ;;
                *)
                  if [ "$have_ref" -eq 1 ]; then
                    exec ${lib.getExe self'.packages.activate} "''${original_args[@]}"
                  fi
                  ref="$1"
                  have_ref=1
                  ;;
              esac
              shift
            done

            current_host="$(hostname -s)"

            case "$ref" in
              *@*)
                exec ${lib.getExe self'.packages.activate} "''${original_args[@]}"
                ;;
              localhost|"$current_host")
                ;;
              *)
                exec ${lib.getExe self'.packages.activate} "''${original_args[@]}"
                ;;
            esac

            repo_root="$HOME/.config/nixos"
            current_root="$(pwd -P)"

            if [ "$current_root" != "$repo_root" ]; then
              echo "activate must be run from $repo_root" >&2
              exit 1
            fi

            subcommand="switch"
            if [ "$dry_run" -eq 1 ]; then
              subcommand="dry-activate"
            fi

            exec sudo -n /run/current-system/sw/bin/nixos-rebuild "$subcommand" --flake "$repo_root#$current_host"
          '';
        };
      };

      default = {
        inherit (self'.packages.activate) meta;

        program = pkgs.writeShellApplication {
          name = "activate-home";
          text = ''
            set -x
            ${lib.getExe self'.packages.activate} "$(id -un)"@
          '';
        };
      };
    };
  };
}
