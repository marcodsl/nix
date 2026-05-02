{flake, ...}: let
  repoRoot = flake.inputs.self;
  packagesDir = repoRoot + /packages;
in
  final: prev: let
    entries = builtins.readDir packagesDir;

    isPackageFile = name: entryType:
      entryType == "regular" && builtins.match ".*\\.nix$" name != null;

    isPackageDirectory = name: entryType:
      entryType == "directory"
      && builtins.pathExists (packagesDir + "/${name}/default.nix");

    isPackageEntry = name: entryType:
      isPackageFile name entryType || isPackageDirectory name entryType;

    packageAttrName = name: entryType:
      if entryType == "regular"
      then prev.lib.removeSuffix ".nix" name
      else name;

    toPackage = name: entryType: {
      name = packageAttrName name entryType;
      value = final.callPackage (packagesDir + "/${name}") {};
    };

    localPackages = prev.lib.pipe entries [
      (prev.lib.filterAttrs isPackageEntry)
      (prev.lib.mapAttrsToList toPackage)
      builtins.listToAttrs
    ];
  in
    localPackages
    // {
      pythonPackagesExtensions =
        (prev.pythonPackagesExtensions or [])
        ++ [
          (_pythonFinal: pythonPrev: {
            fastmcp = pythonPrev.fastmcp.overridePythonAttrs (_old: {
              # fastmcp sampling tests can hang in sandboxed pytestCheckPhase.
              doCheck = false;
            });
          })
        ];
    }
