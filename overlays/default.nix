{flake, ...}: let
  inherit (flake.inputs) self;
  packages = self + /packages;
in
  self: super: let
    entries = builtins.readDir packages;

    toPackage = name: type: {
      name =
        if type == "regular" && builtins.match ".*\\.nix$" name != null
        then builtins.replaceStrings [".nix"] [""] name
        else name;
      value = self.callPackage (packages + "/${name}") {};
    };
  in
    builtins.listToAttrs (builtins.attrValues (builtins.mapAttrs toPackage entries))
