{
  config,
  lib,
  ...
}: let
  mkClaudeAgent = {
    name,
    description,
    model ? "inherit",
    disallowedTools,
    prompt,
  }: ''
    ---
    name: ${name}
    description: ${description}
    model: ${model}
    disallowedTools: ${disallowedTools}
    permissionMode: auto
    ---
    ${prompt}
  '';
in {
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    context = ./CLAUDE.md;

    settings = {
      includeCoAuthoredBy = false;
      theme = "dark";
    };

    skills = let
      mkSkillDir = path:
        lib.pipe (builtins.readDir path) [
          (lib.filterAttrs (_: type: type == "directory"))
          (lib.mapAttrs (name: _: path + "/${name}"))
        ];

      userSkills = mkSkillDir config.me.ai.skills;
      claudeSkills = mkSkillDir ./skills;
    in
      userSkills // claudeSkills;

    agents = {
      researcher = mkClaudeAgent {
        name = "researcher";
        description = "Research subagent that executes thorough searches based on main agent instructions. Searches GitHub repos, fetches files, verifies claims, and reports detailed findings with citations. Designed to work autonomously within a research workflow.";
        disallowedTools = "Bash, Edit";
        prompt = builtins.readFile ./agents/researcher.md;
      };
    };
  };
}
