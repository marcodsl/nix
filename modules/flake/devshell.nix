{inputs, ...}: let
  inherit (inputs) self devenv;
in {
  perSystem = {pkgs, ...}: {
    devShells.default = devenv.lib.mkShell {
      inherit inputs;

      # cachix/devenv's rust language module still references `pkgs.mold-wrapped`
      pkgs = pkgs.extend (_final: prev: {mold-wrapped = prev.mold;});

      modules = [
        (self + /devenv.nix)
      ];
    };
  };
}
