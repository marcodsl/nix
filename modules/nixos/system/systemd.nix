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

      # earlyoom (below) is the sole OOM killer; oomd's SwapUsedLimit
      # misfires on zram occupancy.
      oomd.enable = false;
    };

    # jitterentropy-rngd 1.3.1 calls mlock(2), which the upstream unit's
    # seccomp filter denies → SIGSYS at startup. RDRAND covers entropy on
    # this host; disabling avoids a failed unit on every activation.
    services.jitterentropy-rngd.enable = false;

    services.earlyoom = {
      enable = lib.mkDefault true;
      freeMemThreshold = 5;
      freeSwapThreshold = 10;
      enableNotifications = false;
      extraArgs = [
        "--avoid"
        "^(gnome-shell|gnome-session|gsd-|gdm|dbus-broker|pipewire|wireplumber|Xwayland|gnome-keyring|gcr-|gvfsd)"
        "--prefer"
        "^(electron|chromium|chrome|firefox|node)"
      ];
    };
  };
}
