{
  config,
  lib,
  ...
}: let
  cfg = config.marco.services.caddy;
in {
  options.marco.services.caddy = {
    enable = lib.mkEnableOption "Caddy service";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [80 443];

    services.caddy = {
      enable = true;
    };
  };
}
