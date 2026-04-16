{
  config,
  lib,
  pkgs,
  ...
}: let
  primaryUser = lib.head config.users';
  primaryUserConfig = config.users.users.${primaryUser};

  repoRoot = "${primaryUserConfig.home}/.config/nixos";
  hostName = config.networking.hostName;

  hostFlakeRef = "${repoRoot}\\#${hostName}";
in {
  config = {
    environment.systemPackages = with pkgs; [
      clamav
    ];

    programs.firejail.enable = true;

    security.rtkit.enable = lib.mkDefault true;

    security.polkit = {
      enable = lib.mkDefault true;
      debug = lib.mkDefault false;

      extraConfig = lib.mkIf config.security.polkit.debug ''
        /* Log authorization checks. */
        polkit.addRule(function(action, subject) {
          polkit.log("user " +  subject.user + " is attempting action " + action.id + " from PID " + subject.pid);
        });
      '';
    };

    security.sudo.enable = lib.mkDefault false;
    security.sudo-rs = {
      enable = lib.mkDefault true;
      wheelNeedsPassword = lib.mkDefault true;
      extraRules = [
        {
          users = [primaryUser];
          commands = [
            {
              command = "/run/current-system/sw/bin/nixos-rebuild switch --flake ${hostFlakeRef}";
              options = ["NOPASSWD"];
            }
            {
              command = "/run/current-system/sw/bin/nixos-rebuild dry-activate --flake ${hostFlakeRef}";
              options = ["NOPASSWD"];
            }
          ];
        }
      ];
    };

    services = {
      gnome.gnome-keyring.enable = lib.mkDefault true;

      clamav = {
        daemon.enable = lib.mkDefault true;
        updater.enable = lib.mkDefault true;
      };

      usbguard = {
        enable = lib.mkDefault true;

        IPCAllowedGroups = lib.mkDefault ["wheel" "usbguard"];
        presentDevicePolicy = lib.mkDefault "allow";

        rules = lib.mkDefault ''
          allow with-interface equals { 08:*:* }

          # Reject devices with suspicious combination of interfaces
          reject with-interface all-of { 08:*:* 03:00:* }
          reject with-interface all-of { 08:*:* 03:01:* }
          reject with-interface all-of { 08:*:* e0:*:* }
          reject with-interface all-of { 08:*:* 02:*:* }
        '';
      };
    };
  };
}
