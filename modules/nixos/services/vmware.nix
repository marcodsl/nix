{
  config,
  lib,
  ...
}: let
  cfg = config.marco.services.vmware;
in {
  options.marco.services.vmware.enable = lib.mkEnableOption "VMware host support";

  config = lib.mkIf cfg.enable {
    virtualisation.vmware.host = {
      enable = true;
      extraConfig = ''
        mks.gl.allowUnsupportedDrivers = "TRUE"
        mks.vk.allowUnsupportedDevices = "TRUE"
      '';
    };
  };
}
