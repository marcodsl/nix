{...}: {
  imports = [
    ./audio.nix
    ./kernel.nix
    ./locales.nix
    ./networking.nix
    ./security.nix
    ./systemd.nix
    ./virtualization.nix
  ];
}
