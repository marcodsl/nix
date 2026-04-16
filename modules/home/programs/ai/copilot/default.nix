{
  config,
  lib,
  ...
}: let
  copilotMcpServers = lib.mapAttrs (_: server:
    if server ? command
    then
      server
      // {
        args = server.args or [];
      }
    else server)
  config.programs.mcp.servers;
in {
  home.file = {
    ".copilot/skills" = {
      source = ../skills;
      recursive = true;
    };

    ".copilot/copilot-instructions.md".source = ./copilot-instructions.md;
    ".copilot/instructions/memory-server.md".source = ./instructions/memory-server.md;

    ".copilot/mcp-config.json".text = builtins.toJSON {
      mcpServers = copilotMcpServers;
    };
  };
}
