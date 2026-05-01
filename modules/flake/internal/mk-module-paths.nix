{lib}: rootPath: let
  rootEntries = builtins.readDir rootPath;

  isModuleNixFile = name: entryType:
    entryType
    == "regular"
    && name != "default.nix"
    && builtins.match ".*\\.nix$" name != null;

  isModuleDirectory = name: entryType:
    entryType
    == "directory"
    && builtins.pathExists (rootPath + "/${name}/default.nix");

  isModuleEntry = name: entryType:
    isModuleNixFile name entryType || isModuleDirectory name entryType;

  moduleEntries = lib.filterAttrs isModuleEntry rootEntries;
  entryNames = builtins.attrNames moduleEntries;

  entryAttrName = name: entryType:
    if entryType == "regular"
    then lib.removeSuffix ".nix" name
    else name;

  declaredAttrNames = ["default"] ++ map (name: entryAttrName name moduleEntries.${name}) entryNames;

  duplicateAttrNames = lib.filter (
    attrName:
      builtins.length (lib.filter (otherAttrName: otherAttrName == attrName) declaredAttrNames) > 1
  ) (lib.unique declaredAttrNames);

  mkModulePathAttr = name: entryType: {
    name = entryAttrName name entryType;
    value = rootPath + "/${name}";
  };

  generatedModulePaths = builtins.listToAttrs (map (name: mkModulePathAttr name moduleEntries.${name}) entryNames);
in
  if duplicateAttrNames != []
  then throw "module path collision under ${toString rootPath}: ${lib.concatStringsSep ", " duplicateAttrNames}"
  else
    {default = rootPath;}
    // generatedModulePaths
