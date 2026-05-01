{...}: {
  imports = [
    ./audio.nix
    ./kernel.nix
    ./locales.nix
    ./networking.nix
    ./security
    ./systemd.nix
    ./virtualization.nix
  ];
}
