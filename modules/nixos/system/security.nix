{
  config,
  flake,
  lib,
  pkgs,
  ...
}: let
  primaryUser = lib.head config.users';
  primaryUserHome = config.users.users.${primaryUser}.home;

  activateLocalSystem = let
    repoRoot = "${primaryUserHome}/.config/nixos";
  in
    pkgs.callPackage (flake.inputs.self + /packages/activate-local-system) {
      hostName = config.networking.hostName;
      inherit repoRoot;
    };
in {
  config = {
    environment.systemPackages = with pkgs; [
      activateLocalSystem
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
              command = "/run/current-system/sw/bin/activate-local-system";
              options = ["NOPASSWD"];
            }
            {
              command = lib.getExe activateLocalSystem;
              options = ["NOPASSWD"];
            }
          ];
        }
      ];
    };

    services = {
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
