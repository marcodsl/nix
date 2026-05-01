{
  inputs,
  self,
  ...
}: let
  flakeArgs = import ./internal/mk-flake-args.nix {inherit inputs self;};
in {
  flake = {
    darwinConfigurations = {};
    darwinModules = {};

    flakeModules = {
      activate-home = ./activate-home.nix;
      devshell = ./devshell.nix;
      neovim = ./neovim.nix;
      toplevel = ./toplevel.nix;
    };

    overlays.default = import "${self}/overlays" flakeArgs;
  };
}
