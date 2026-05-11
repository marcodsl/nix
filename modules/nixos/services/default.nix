{...}: {
  imports = [
    ./caddy.nix
    ./deskflow.nix
    ./loaders.nix
    ./mullvad.nix
    ./ntpd.nix
    ./ollama.nix
    ./podman.nix
    ./tailscale.nix
    ./vector.nix
    ./vmware.nix
  ];

  config = {
    services = {
      openssh.enable = true;
    };
  };
}
