{
  config,
  lib,
  pkgs,
  ...
}: let
  skillsSourceDir = ../skills;
  installedSkillsDir = "${config.home.homeDirectory}/.codex/skills";

  managedSkillNames = lib.pipe (builtins.readDir skillsSourceDir) [
    (lib.filterAttrs (_: type: type == "directory"))
    builtins.attrNames
  ];

  # Codex mutates skill files at runtime, so deploy writable copies instead
  # of nix-store symlinks (cf. copilot, which uses home.file).
  installSkillsScript = ''
    export PATH=${lib.makeBinPath [pkgs.coreutils]}:$PATH

    skills_src=${lib.escapeShellArg (toString skillsSourceDir)}
    skills_dst=${lib.escapeShellArg installedSkillsDir}

    install_skill() {
      local name=$1
      local target="$skills_dst/$name"

      if [ -d "$target" ] && [ ! -L "$target" ]; then
        $DRY_RUN_CMD chmod -R u+w "$target"
      fi
      $DRY_RUN_CMD rm -rf "$target"
      $DRY_RUN_CMD cp -RL "$skills_src/$name" "$target"
      $DRY_RUN_CMD chmod -R u+w "$target"
    }

    if [ -L "$skills_dst" ]; then
      $DRY_RUN_CMD rm "$skills_dst"
    fi
    $DRY_RUN_CMD mkdir -p "$skills_dst"

    ${lib.concatMapStringsSep "\n"
      (name: "install_skill ${lib.escapeShellArg name}")
      managedSkillNames}
  '';
in {
  home = {
    packages = [pkgs.codex];

    activation.copyCodexSkills =
      lib.hm.dag.entryAfter ["writeBoundary"] installSkillsScript;
  };
}
