{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.marco.services.deskflow;
in {
  options.marco.services.deskflow = {
    enable = lib.mkEnableOption "Deskflow keyboard/mouse sharing";
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open TCP 24800 for incoming server connections.";
    };
    package = lib.mkPackageOption pkgs "deskflow" {};
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [24800];
  };
}
