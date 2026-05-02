{...}: {
  imports = [
    ./aliases.nix
    ./cliff.nix
    ./ignores.nix
    ./settings.nix
  ];

  programs = {
    git-credential-oauth.enable = true;

    git = {
      enable = true;

      # SSH commit signing — uncomment to enable.
      # GitHub/GitLab verify SSH signatures since 2022; reuses the existing
      # SSH key, no GPG agent required.
      signing.format = null;
      # signing = {
      #   format = "ssh";
      #   key = "~/.ssh/id_ed25519.pub";
      #   signByDefault = true;
      # };

      maintenance = {
        enable = true;
        repositories = [
          "/home/marco/.config/nixos"
        ];
      };
    };
  };
}
