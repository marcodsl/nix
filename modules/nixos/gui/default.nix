{
  imports = [
    ./gnome.nix
    ./wayland.nix
  ];
  services.xserver.enable = true;
}
