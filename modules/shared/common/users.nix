{
  flake,
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (flake.inputs) self;

  mapListToAttrs = names: f:
    lib.listToAttrs (map (name: {
        inherit name;
        value = f name;
      })
      names);
in {
  options = {
    users' = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of usernames";
      defaultText = "All users under ./configurations/home are included by default";

      default = lib.pipe (self + /configurations/home) [
        builtins.readDir
        (lib.filterAttrs (_: type: type == "regular"))
        builtins.attrNames
        (map (lib.removeSuffix ".nix"))
      ];
    };
  };

  config = {
    users.users = mapListToAttrs config.users' (
      name:
        lib.optionalAttrs pkgs.stdenv.isLinux {
          isNormalUser = true;
          extraGroups = ["networkmanager" "wheel"];
          description = "Marco";
          shell = pkgs.zsh;
        }
    );

    home-manager = {
      useGlobalPkgs = true;

      users = mapListToAttrs config.users' (name: {
        imports = [(self + /configurations/home/${name}.nix)];
      });
    };

    nix.settings.trusted-users = lib.singleton "root" ++ config.users';
  };
}
