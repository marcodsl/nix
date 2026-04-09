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

      default = let
        entries = builtins.readDir (self + /configurations/home);
      in
        map (f: lib.removeSuffix ".nix" f)
        (builtins.filter (f: entries.${f} == "regular") (builtins.attrNames entries));
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
