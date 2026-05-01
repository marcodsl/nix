{pkgs, ...}: {
  imports = [
    ./gcloud.nix
    ./libreoffice.nix
    ./security
  ];

  config = {
    home.packages = with pkgs; [
      # Utilities
      gnumake
      less
      sd
      tree

      # Development
      act
      alejandra
      biome
      bun
      cachix
      devenv
      jython
      nil
      nodejs
      zx

      # Communication
      discord
      signal-desktop

      # Browsers
      brave
      google-chrome

      # Productivity
      affine
      bitwarden-desktop
      bruno

      # Media
      spotify
    ];
  };
}
