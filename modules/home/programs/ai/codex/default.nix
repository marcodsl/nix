{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatMapStringsSep filterAttrs;

  homeDirectory = config.home.homeDirectory;
  skillsSource = ../skills;
  skillsDir = "${homeDirectory}/.codex/skills";
  skillEntries = builtins.readDir skillsSource;
  managedSkills = builtins.attrNames (filterAttrs (_: type: type == "directory") skillEntries);

  skillSource = name: "${skillsSource}/${name}";
  skillTarget = name: "${skillsDir}/${name}";

  copySkillCommand = name: let
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

  copySkillCommands = concatMapStringsSep "\n" copySkillCommand managedSkills;
in {
  home = {
    packages = with pkgs; [
      codex
    ];

    activation.copyCodexSkills = lib.hm.dag.entryAfter ["writeBoundary"] ''
      skills_dir=${lib.escapeShellArg skillsDir}

      if [ -L "$skills_dir" ]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm "$skills_dir"
      fi

      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$skills_dir"

      ${copySkillCommands}
    '';
  };
}
