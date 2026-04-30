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
    localPackages = builtins.listToAttrs (builtins.attrValues (builtins.mapAttrs toPackage entries));
  in
    localPackages
    // {
      pythonPackagesExtensions =
        (super.pythonPackagesExtensions or [])
        ++ [
          (_final: prev: {
            fastmcp = prev.fastmcp.overridePythonAttrs (_old: {
              # fastmcp sampling tests can hang in sandboxed pytestCheckPhase.
              doCheck = false;
            });
          })
        ];
    }
