{
  config,
  flake,
  pkgs,
  lib,
  osConfig ? null,
  ...
}: let
  inherit (flake.inputs) self;
  sharesSystemPkgs = osConfig != null && (osConfig.home-manager.useGlobalPkgs or false);
in {
  nixpkgs = lib.mkIf (!sharesSystemPkgs) {
    config.allowUnfree = true;
    overlays = lib.attrValues self.overlays;
  };

  nix = {
    package = lib.mkDefault pkgs.nix;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  home.packages = [
    config.nix.package
  ];
}
