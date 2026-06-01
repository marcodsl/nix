{
  flake,
  lib,
  pkgs,
  ...
}: let
  inherit (flake.inputs) self;
in {
  nixpkgs = {
    config.allowUnfree = true;
    overlays = lib.attrValues self.overlays;
  };

  nix = {
    package = pkgs.lix;

    nixPath = [
      "nixpkgs=${flake.inputs.nixpkgs}"
    ];

    registry.nixpkgs.flake = flake.inputs.nixpkgs;

    optimise = {
      automatic = true;
      dates = ["03:45"];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    settings = let
      mib = 1024 * 1024;
      gib = 1024 * mib;

      # devenv.cachix.org intentionally omitted: devenv re-adds it inside
      # dev shells (and it never reaches the system closure), so listing it
      # here only triggers devenv's "already present in the substituters list"
      # warning. marcodsl stays so plain `nh os switch` still pulls our cache.
      substituters = [
        "https://cache.nixos.org"
        "https://cachix.cachix.org"
        "https://marcodsl.cachix.org"
        "https://nix-community.cachix.org"
      ];
    in {
      # mkForce so the NixOS default `https://cache.nixos.org/` is not
      # concatenated onto this list, which otherwise duplicates cache.nixos.org.
      substituters = lib.mkForce substituters;

      min-free = 100 * mib;
      max-free = 1 * gib; # Keep the explicit 1 for clarity

      trusted-substituters = [
        "https://cache.nixos.org"
        "https://cachix.cachix.org"
        "https://marcodsl.cachix.org"
        "https://nix-community.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
        "marcodsl.cachix.org-1:gH4jaxy05qaIKpJ459Wk4rmDzVhSzVbViwdIsrvlH9k="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      builders-use-substitutes = true;
      connect-timeout = 10;
      cores = 4;
      download-attempts = 10;
      http-connections = 50;
      keep-going = true;
      max-call-depth = "1000000";
      max-jobs = 2;
      max-substitution-jobs = 32;
      narinfo-cache-negative-ttl = 300;
      narinfo-cache-positive-ttl = 432000;
      stalled-download-timeout = 60;
      use-cgroups = true;
      warn-dirty = false;

      experimental-features = [
        "nix-command"
        "flakes"
        "cgroups"
      ];
    };
  };
}
