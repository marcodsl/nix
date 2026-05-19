{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.marco.services.cloudflared;
in {
  options.marco.services.cloudflared.enable = lib.mkEnableOption "cloudflared tunnel connector";

  config = lib.mkIf cfg.enable {
    users = {
      users.cloudflared = {
        isSystemUser = true;
        group = "cloudflared";
        description = "cloudflared tunnel service user";
      };

      groups.cloudflared = {};
    };

    systemd.services.cloudflared = {
      description = "Cloudflare Tunnel connector";
      wantedBy = ["multi-user.target"];
      wants = ["network-online.target"];
      after = ["network-online.target" "nftables.service" "sops-nix.service"];

      serviceConfig = {
        User = "cloudflared";
        Group = "cloudflared";

        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file=%d/token";

        LoadCredential = "token:${config.sops.secrets."cloudflared/token".path}";

        Restart = "on-failure";
        RestartSec = "5s";

        RuntimeDirectory = "cloudflared";

        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = ["@system-service" "~@privileged" "~@resources"];
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
      };
    };

    networking.nftables.preCheckRuleset = ''
      sed 's/meta skuid "cloudflared"/meta skuid "root"/g' -i ruleset.conf
    '';

    networking.nftables.tables.cloudflared-egress = {
      family = "inet";
      content = ''
        chain output {
          type filter hook output priority 0; policy accept;
          meta skuid "cloudflared" jump cloudflared-egress-filter
        }

        chain cloudflared-egress-filter {
          ct state { established, related } accept
          meta l4proto { tcp, udp } th dport 53 accept
          meta l4proto udp udp dport 443 accept
          tcp dport { 443, 7844 } accept
          ip daddr 127.0.0.1 tcp dport 8000 accept
          counter reject
        }
      '';
    };
  };
}
