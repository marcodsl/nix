{...}: {
  imports = [
    ./audio.nix
    ./kernel.nix
    ./locales.nix
    ./networking.nix
    ./power.nix
    ./security
    ./systemd.nix
    ./virtualization.nix
  ];
}
