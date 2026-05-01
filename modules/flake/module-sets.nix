{lib, ...}: let
  mkModulePaths = import ./internal/mk-module-paths.nix {inherit lib;};
in {
  flake = {
    homeModules = mkModulePaths ../home;
    nixosModules = mkModulePaths ../nixos;
  };
}
