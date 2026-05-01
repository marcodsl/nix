{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatMapStringsSep filterAttrs;

  homeDirectory = config.home.homeDirectory;
  skillsSourceDir = ../skills;
  installedSkillsDir = "${homeDirectory}/.codex/skills";
  skillEntries = builtins.readDir skillsSourceDir;
  managedSkillNames = builtins.attrNames (filterAttrs (_: entryType: entryType == "directory") skillEntries);

  skillSource = name: "${skillsSourceDir}/${name}";
  skillTarget = name: "${installedSkillsDir}/${name}";

  copyManagedSkillCommand = name: let
    source = lib.escapeShellArg (skillSource name);
    target = lib.escapeShellArg (skillTarget name);
  in ''
    if [ -d ${target} ] && [ ! -L ${target} ]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod -R u+w ${target}
    fi

    $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -rf ${target}
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/cp -RL ${source} ${target}
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod -R u+w ${target}
  '';

  copyManagedSkillCommands = concatMapStringsSep "\n" copyManagedSkillCommand managedSkillNames;
in {
  home = {
    packages = with pkgs; [
      codex
    ];

    activation.copyCodexSkills = lib.hm.dag.entryAfter ["writeBoundary"] ''
      skills_dir=${lib.escapeShellArg installedSkillsDir}

      if [ -L "$skills_dir" ]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm "$skills_dir"
      fi

      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$skills_dir"

      ${copyManagedSkillCommands}
    '';
  };
}
