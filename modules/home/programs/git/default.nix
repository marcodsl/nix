{pkgs, ...}: {
  imports = [
    ./aliases.nix
    ./ignores.nix
    ./settings.nix
  ];

  programs = {
    git-credential-oauth.enable = true;

    git = {
      enable = true;
      package = pkgs.gitFull;

      signing.format = null;
    };
  };
}
