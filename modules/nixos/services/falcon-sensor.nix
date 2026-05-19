# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.marco.services.falcon-sensor;
  crowdStrikeRoot = "/opt/CrowdStrike";
  writableDirs = ["Packages" "Falcon4IT" "ASPM"];
  writableDirPattern = lib.concatStringsSep "|" writableDirs;
  installWritableDirs =
    lib.concatMapStringsSep "\n"
    (dir: "install -d -m 0750 ${crowdStrikeRoot}/${dir}")
    writableDirs;

  refreshScript = pkgs.writeShellApplication {
    name = "falcon-refresh-tree";
    runtimeInputs = [pkgs.coreutils pkgs.findutils];
    text = ''
      install -d -m 0755 ${crowdStrikeRoot}
      ${installWritableDirs}

      package_stamp=${crowdStrikeRoot}/.nix-package
      if [ -f "$package_stamp" ] && [ "$(cat "$package_stamp")" = ${lib.escapeShellArg "${cfg.package}"} ]; then
        exit 0
      fi

      # Refresh symlinks to package binaries on every activation.
      # `-type l` ensures we only delete symlinks, preserving writable state files
      # (falconstore) and writable subdirectories.
      find ${crowdStrikeRoot} -maxdepth 1 -type l -delete

      for src in ${cfg.package}${crowdStrikeRoot}/*; do
        name="$(basename "$src")"
        # Writable state dirs must remain real directories, not store symlinks.
        case "$name" in
          ${writableDirPattern}) continue ;;
        esac
        ln -s "$src" "${crowdStrikeRoot}/$name"
      done

      printf '%s\n' ${lib.escapeShellArg "${cfg.package}"} > "$package_stamp"
    '';
  };

  registerScript = pkgs.writeShellApplication {
    name = "falcon-register";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      cid="$(cat "$CREDENTIALS_DIRECTORY/cid")"

      # Always pin the backend to eBPF user-mode: vendor sensor 18909 has no
      # kernel module for Linux 6.18.x, so the default kmod backend exits 1.
      backend_stamp=${crowdStrikeRoot}/.nix-backend
      if [ ! -f "$backend_stamp" ] || [ "$(cat "$backend_stamp")" != bpf ]; then
        ${crowdStrikeRoot}/falconctl -s --backend=bpf -f
        printf '%s\n' bpf > "$backend_stamp"
      fi

      current="$(${crowdStrikeRoot}/falconctl -g --cid 2>/dev/null || true)"
      case "$current" in
        *"$cid"*)
          echo "Falcon already registered with the configured CID."
          exit 0
          ;;
      esac

      ${crowdStrikeRoot}/falconctl -s --cid="$cid" -f
    '';
  };
in {
  options.marco.services.falcon-sensor = {
    enable = lib.mkEnableOption "CrowdStrike Falcon Sensor (eBPF user-mode)";

    package = lib.mkOption {
      type = lib.types.package;
      description = "Unwrapped Falcon Sensor package (output of packages/falcon-sensor).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
        message = "Falcon Sensor module only supports x86_64-linux.";
      }
    ];

    systemd.services.falcon-refresh-tree = {
      description = "Refresh /opt/CrowdStrike symlink farm to current Falcon package";
      wantedBy = ["multi-user.target"];
      before = ["falcon-register.service" "falcon-sensor.service"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = lib.getExe refreshScript;
      };
    };

    systemd.services.falcon-register = {
      description = "Register CrowdStrike Falcon Sensor CID";
      wantedBy = ["multi-user.target"];
      after = ["sops-nix.service" "falcon-refresh-tree.service"];
      requires = ["falcon-refresh-tree.service"];
      before = ["falcon-sensor.service"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        LoadCredential = "cid:${config.sops.secrets."falcon/cid".path}";
        ExecStart = lib.getExe registerScript;
      };
    };

    systemd.services.falcon-sensor = {
      description = "CrowdStrike Falcon Sensor";
      wantedBy = ["multi-user.target" "sysinit.target"];
      requires = ["falcon-register.service"];
      after = ["falcon-register.service"];

      environment = {
        LD_LIBRARY_PATH = "${pkgs.zlib}/lib";
      };

      serviceConfig = {
        Type = "forking";
        PIDFile = "/var/run/falcond.pid";
        ExecStartPre = "${crowdStrikeRoot}/falconctl -g --cid";
        ExecStart = "${crowdStrikeRoot}/falcond";
        Restart = "no";
        TimeoutStopSec = "60s";
        KillMode = "control-group";
        KillSignal = "SIGTERM";
        Delegate = true;
      };
    };
  };
}
