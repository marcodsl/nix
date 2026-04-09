{...}: {
  imports = [
    ./caddy.nix
    ./loaders.nix
    ./mullvad.nix
    ./ntpd.nix
    ./ollama.nix
    ./podman.nix
    ./tailscale.nix
    ./vmware.nix
  ];

  config = {
    services = {
      openssh.enable = true;
    };
  };
}
