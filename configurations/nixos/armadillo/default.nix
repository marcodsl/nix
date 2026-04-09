{
  config,
  flake,
  lib,
  ...
}: let
  inherit (flake) inputs;
  inherit (inputs) arion nixos-hardware self sops-nix;
in {
  imports = [
    arion.nixosModules.arion
    sops-nix.nixosModules.sops

    nixos-hardware.nixosModules.common-pc-laptop-ssd
    nixos-hardware.nixosModules.lenovo-ideapad-s145-15api

    self.nixosModules.default
    self.nixosModules.gui

    ./configuration.nix
  ];

  sops = {
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    defaultSopsFile = "${self}/secrets/hosts/armadillo.yaml";
    validateSopsFiles = true;

    secrets."github/token" = {};

    templates."nix/github-access-tokens.conf" = {
      path = "/etc/nix/github-access-tokens.conf";
      content = ''
        extra-access-tokens = github.com=${config.sops.placeholder."github/token"}
      '';
      owner = "root";
      group = config.users.users.marco.group;
      mode = "0440";
    };
  };

  nix = {
    extraOptions = lib.mkAfter ''
      !include ${config.sops.templates."nix/github-access-tokens.conf".path}
    '';
  };

  marco.services = {
    caddy.enable = true;
    mullvad.enable = true;
    ollama.enable = true;
    tailscale.enable = true;
    vmware.enable = true;
  };
}
