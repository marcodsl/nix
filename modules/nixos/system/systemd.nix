{lib, ...}: {
  config = {
    systemd = {
      settings.Manager = {
        DefaultIOAccounting = lib.mkDefault true;
        DefaultIPAccounting = lib.mkDefault true;

        DefaultTimeoutStartSec = lib.mkDefault "10s";
        DefaultTimeoutStopSec = lib.mkDefault "10s";
        DefaultTimeoutAbortSec = lib.mkDefault "10s";
        DefaultDeviceTimeoutSec = lib.mkDefault "10s";
      };
    };
  };
}
