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
    };

    systemd.services.tailscaled.after = ["nftables.service"];
  };
}
