{
  config,
  lib,
  ...
}: let
  primaryUser = lib.head config.users';
  primaryUserHome = config.users.users.${primaryUser}.home;
  flakeRepoPath = "${primaryUserHome}/.config/nixos";
in {
  config = {
    programs.nh = {
      enable = true;
      flake = flakeRepoPath;
    };
  };
}
