{lib, ...}: {
  services = {
    gnome.gnome-keyring.enable = lib.mkDefault true;

    clamav = {
      daemon.enable = lib.mkDefault true;
      updater.enable = lib.mkDefault true;
    };
  };
}
