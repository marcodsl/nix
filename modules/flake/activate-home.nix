{
  perSystem = {
    self',
    pkgs,
    lib,
    ...
  }: let
    activateExe = lib.getExe self'.packages.activate;
    nhExe = lib.getExe pkgs.nh;
  in {
    apps = {
      activate = {
        inherit (self'.packages.activate) meta;

        program = pkgs.writeShellApplication {
          name = "activate-system";
          runtimeInputs = [pkgs.coreutils pkgs.hostname];
          text = ''
            set -euo pipefail

            original_args=("$@")
            target_ref="localhost"
            have_target_ref=0
            dry_run=0

            handoff_to_package_activate() {
              exec ${activateExe} "''${original_args[@]}"
            }

            while [ "$#" -gt 0 ]; do
              case "$1" in
                --dry-run)
                  dry_run=1
                  ;;
                -*)
                  handoff_to_package_activate
                  ;;
                *)
                  if [ "$have_target_ref" -eq 1 ]; then
                    handoff_to_package_activate
                  fi
                  target_ref="$1"
                  have_target_ref=1
                  ;;
              esac
              shift
            done

            current_host="$(hostname -s)"

            case "$target_ref" in
              *@*)
                handoff_to_package_activate
                ;;
              localhost|"$current_host")
                ;;
              *)
                handoff_to_package_activate
                ;;
            esac

            repo_root="$HOME/.config/nixos"
            current_root="$(pwd -P)"

            if [ "$current_root" != "$repo_root" ]; then
              echo "activate must be run from $repo_root" >&2
              exit 1
            fi

            if [ -e /etc/NIXOS ]; then
              if [ "$dry_run" -eq 1 ]; then
                dry_args=(--dry)
              else
                dry_args=()
              fi

              nh_args=(
                ${nhExe}
                os
                switch
                -H "$current_host"
                -R
                "''${dry_args[@]}"
                "$repo_root"
              )

              exec sudo "''${nh_args[@]}"
            fi

            home_args=("$(id -un)@")
            if [ "$dry_run" -eq 1 ]; then
              home_args+=(--dry-run)
            fi

            exec ${activateExe} "''${home_args[@]}"
          '';
        };
      };

      default = {
        inherit (self'.packages.activate) meta;

        program = pkgs.writeShellApplication {
          name = "activate-home";
          text = ''
            set -x
            exec ${activateExe} "$(id -un)@" "$@"
          '';
        };
      };
    };
  };
}
