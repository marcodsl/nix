{...}: {
  imports = [
    ./caddy.nix
    ./cloudflared.nix
    ./deskflow.nix
    ./falcon-sensor.nix
    ./litellm.nix
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
