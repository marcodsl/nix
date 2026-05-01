{lib, ...}: let
  skillsDir = ../skills;
  skillEntries = builtins.readDir skillsDir;
  skillDirectories = lib.filterAttrs (_: entryType: entryType == "directory") skillEntries;
  configuredSkills = lib.mapAttrs (name: _: skillsDir + "/${name}") skillDirectories;
in {
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    settings = {
      includeCoAuthoredBy = false;
      theme = "dark";
    };

    skills = configuredSkills;
  };
}
