{
  config,
  lib,
  ...
}: let
  cfg = config.marco.services.mullvad;
in {
  options.marco.services.mullvad.enable = lib.mkEnableOption "Mullvad service";

  config = lib.mkIf cfg.enable {
    services.mullvad-vpn.enable = true;

    systemd.services.mullvad-daemon.serviceConfig = {
      Nice = 5;
      CPUWeight = 40;
      IOSchedulingClass = "best-effort";
      IOSchedulingPriority = 5;
    };
  };
}
