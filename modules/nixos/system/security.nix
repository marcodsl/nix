{
  config,
  lib,
  pkgs,
  ...
}: {
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
