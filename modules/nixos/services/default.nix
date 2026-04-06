{...}: {
  imports = [
    ./caddy.nix
    ./loaders.nix
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
