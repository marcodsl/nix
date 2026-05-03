{
  config,
  flake,
  lib,
  ...
}: let
  inherit (flake) inputs;
  inherit (inputs) arion nixos-hardware nix-mineral self sops-nix;
in {
  imports = [
    arion.nixosModules.arion
    sops-nix.nixosModules.sops

    nixos-hardware.nixosModules.common-pc-laptop-ssd
    nixos-hardware.nixosModules.lenovo-ideapad-s145-15api
    nix-mineral.nixosModules.nix-mineral

    self.nixosModules.default
    self.nixosModules.gui
    self.nixosModules.sops-secrets

    ./hardware.nix
  ];

  nix = {
    extraOptions = lib.mkAfter ''
      !include ${config.sops.templates."nix/github-access-tokens.conf".path}
    '';
  };

  nix-mineral = {
    enable = true;
    preset = "performance";

    filesystems.enable = false;

    settings = {
      debug.quiet-boot = true;

      etc.kicksecure-module-blacklist = true;

      misc.nix-wheel = false;

      network.tcp-timestamps = false;
    };

    extras = {
      system.minimize-swapping = false;
    };
  };

  marco = {
    wifi = {
      interface = "wlp2s0";
      staticAddress = "192.168.0.108/24";
      gateway = "192.168.0.1";
      dns = "1.1.1.1 1.0.0.1";
    };

    services = {
      caddy.enable = true;
      mullvad.enable = true;
      ollama.enable = false;
      tailscale.enable = true;
      vmware.enable = false;
    };
  };
}
