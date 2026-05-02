{
  config,
  lib,
  ...
}: let
  cfg = config.marco.services.tailscale;
in {
  options.marco.services.tailscale.enable = lib.mkEnableOption "Tailscale service";

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      permitCertUid = "caddy";
      extraSetFlags = ["--accept-dns=false"];
    };

    systemd.services.tailscaled = {
      after = ["nftables.service"];
      serviceConfig = {
        Nice = 5;
        CPUWeight = 40;
        IOSchedulingClass = "best-effort";
        IOSchedulingPriority = 5;
      };
    };
  };
}
