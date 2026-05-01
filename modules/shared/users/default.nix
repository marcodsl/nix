{
  flake,
  pkgs,
  lib,
  config,
  ...
}: let
  repoRoot = flake.inputs.self;
  usersDir = repoRoot + /users;

  mkNamedAttrs = names: valueForName:
    lib.listToAttrs (map (name: {
        inherit name;
        value = valueForName name;
      })
      names);

  userHomeModule = username: usersDir + "/${username}/home.nix";
  isManagedUser = username: entryType:
    entryType == "directory" && builtins.pathExists (userHomeModule username);

  defaultUsers = let
    userEntries = builtins.readDir usersDir;
  in
    builtins.filter (username: isManagedUser username userEntries.${username}) (builtins.attrNames userEntries);

  mkSystemUser = _username:
    lib.optionalAttrs pkgs.stdenv.isLinux {
      isNormalUser = true;
      extraGroups = ["networkmanager" "wheel"];
      description = "Marco";
      shell = pkgs.zsh;
    };

  mkHomeManagerUser = username: {
    imports = [(userHomeModule username)];
  };
in {
  options = {
    users' = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of usernames";
      defaultText = "All users under ./users are included by default";

      default = defaultUsers;
    };
  };

  config = {
    users.users = mkNamedAttrs config.users' mkSystemUser;

    home-manager = {
      useGlobalPkgs = true;

      users = mkNamedAttrs config.users' mkHomeManagerUser;
    };

    nix.settings.trusted-users = ["root"] ++ config.users';
  };
}
