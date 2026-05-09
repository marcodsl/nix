{lib, ...}: {
  services = {
    gnome.gnome-keyring.enable = lib.mkDefault true;

    clamav = {
      daemon.enable = lib.mkDefault false;
      updater.enable = lib.mkDefault true;
    };
  };

  systemd.services.clamav-freshclam.serviceConfig = {
    Nice = 19;
    CPUSchedulingPolicy = "idle";
    IOSchedulingClass = "idle";
    IOSchedulingPriority = 7;
  };
}
