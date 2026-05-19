{
  self,
  lib,
  ...
}: let
  mkModulePaths = import "${self}/lib/module-paths.nix" {inherit lib;};
in {
  flake = {
    homeModules = mkModulePaths "${self}/modules/home";
    nixosModules = mkModulePaths "${self}/modules/nixos";
  };
}
