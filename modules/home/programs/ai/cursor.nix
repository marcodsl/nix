{config, ...}: {
  home.file = {
    ".cursor/skills" = {
      source = ./skills;
      recursive = true;
    };

    ".cursor/mcp.json".text = builtins.toJSON {
      mcpServers = config.programs.mcp.servers;
    };
  };
}
