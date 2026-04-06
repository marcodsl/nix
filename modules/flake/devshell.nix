{inputs, ...}: let
  inherit (inputs) self devenv;
in {
  perSystem = {pkgs, ...}: {
    devShells.default = devenv.lib.mkShell {
      inherit inputs pkgs;

      modules = [
        (self + /devenv.nix)
      ];
    };
  };
}
