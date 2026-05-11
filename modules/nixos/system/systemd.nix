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

      oomd = {
        enable = lib.mkDefault true;
        enableUserSlices = lib.mkDefault true;
        enableRootSlice = lib.mkDefault true;
        enableSystemSlice = lib.mkDefault true;
        settings.OOM = {
          DefaultMemoryPressureDurationSec = "5s";
          DefaultMemoryPressureLimit = "60%";
          SwapUsedLimit = "90%";
        };
      };
    };

    services.earlyoom = {
      enable = lib.mkDefault true;
      freeMemThreshold = 5;
      freeSwapThreshold = 10;
      enableNotifications = false;
    };
  };
}
