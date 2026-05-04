{config, ...}: {
  programs.github-copilot-cli = {
    enable = true;
    enableMcpIntegration = true;
    context = ./copilot-instructions.md;
    skills = config.me.ai.skills;
  };
}
