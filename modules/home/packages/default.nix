{pkgs, ...}: {
  imports = [
    ./gcloud.nix
    ./libreoffice.nix
    ./security.nix
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
      cachix
      devenv
      github-copilot-cli
      jython
      nil
      nodejs-slim
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
