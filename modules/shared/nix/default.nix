{
  flake,
  lib,
  ...
}: let
  inherit (flake.inputs) self;
in {
  nixpkgs = {
    config.allowUnfree = true;
    overlays = lib.attrValues self.overlays;
  };

  nix = {
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

      substituters = [
        "https://cache.nixos.org"
        "https://cachix.cachix.org"
        "https://devenv.cachix.org"
        "https://marcodsl.cachix.org"
        "https://nix-community.cachix.org"
      ];
    in {
      inherit substituters;

      min-free = 100 * mib;
      max-free = 1 * gib; # Keep the explicit 1 for clarity

      trusted-substituters = [
        "https://cache.nixos.org"
        "https://cachix.cachix.org"
        "https://devenv.cachix.org"
        "https://marcodsl.cachix.org"
        "https://nix-community.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "marcodsl.cachix.org-1:gH4jaxy05qaIKpJ459Wk4rmDzVhSzVbViwdIsrvlH9k="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      connect-timeout = 10;
      download-attempts = 10;
      download-buffer-size = 512 * mib;
      http-connections = 50;
      keep-going = true;
      max-call-depth = "1000000";
      max-jobs = "auto";
      max-substitution-jobs = 32;
      narinfo-cache-negative-ttl = 300;
      narinfo-cache-positive-ttl = 432000;
      stalled-download-timeout = 60;
      use-cgroups = true;

      experimental-features = [
        "nix-command"
        "flakes"
        "cgroups"
      ];
    };
  };
}
