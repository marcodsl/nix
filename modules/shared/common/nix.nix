{...}: {
  nix = {
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
    in {
      min-free = 100 * mib;
      max-free = 1 * gib; # Keep the explicit 1 for clarity

      substituters = [
        "https://cache.nixos.org"
        "https://cachix.cachix.org"
        "https://devenv.cachix.org"
        "https://nix-community.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      connect-timeout = 10;
      download-attempts = 10;
      download-buffer-size = 512 * mib;
      http-connections = 50;
      keep-going = true;
      max-jobs = 4;
      max-substitution-jobs = 32;
      narinfo-cache-negative-ttl = 300;
      stalled-download-timeout = 60;
      use-cgroups = true;

      experimental-features = [
        "nix-command"
        "flakes"
        "cgroups"
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;
}
