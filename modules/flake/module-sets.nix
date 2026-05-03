{
  lib,
  self,
  ...
}: let
  mkModulePaths = import ./internal/mk-module-paths.nix {inherit lib;};
  sopsModules = import ./sops.nix {inherit self;};
in {
  flake = {
    homeModules =
      mkModulePaths ../home
      // {
        sops-secrets = sopsModules.home;
      };
    nixosModules =
      mkModulePaths ../nixos
      // {
        sops-secrets = sopsModules.nixos;
      };
  };
}
