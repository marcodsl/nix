{lib, ...}: {
  services = {
    gnome.gnome-keyring.enable = lib.mkDefault true;

    clamav = {
      daemon = {
        enable = lib.mkDefault true;
        settings = {
          ExcludePath = [
            "^/proc/"
            "^/sys/"
            "^/dev/"
            "^/run/"
            "^/nix/store/"
            "^/var/cache/"
            "^/var/log/"
            "^/var/lib/containers/"
            "^/home/.*/.cache/"
          ];
          MaxThreads = 4;
          MaxScanSize = "500M";
          MaxFileSize = "200M";
          MaxRecursion = 20;
        };
      };
      updater.enable = lib.mkDefault true;
    };
  };

  systemd.services.clamav-daemon.serviceConfig = {
    Nice = 15;
    IOSchedulingClass = "idle";
    IOSchedulingPriority = 7;
    CPUWeight = 20;
  };

  systemd.services.clamav-freshclam.serviceConfig = {
    Nice = 19;
    CPUSchedulingPolicy = "idle";
    IOSchedulingClass = "idle";
    IOSchedulingPriority = 7;
  };
}
