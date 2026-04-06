{
  config,
  flake,
  pkgs,
  ...
}: let
  nix-index-packages = flake.inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    flake.inputs.nix-index-database.homeModules.nix-index
  ];

  programs = {
    nix-index = {
      enable = true;
      package = nix-index-packages.nix-index-with-small-db;
      symlinkToCacheHome = false;
    };

    nix-index-database.comma.enable = true;
  };

  home.file."${config.xdg.cacheHome}/nix-index/files".source = nix-index-packages.nix-index-small-database;
}
