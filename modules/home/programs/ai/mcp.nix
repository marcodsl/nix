{
  pkgs,
  lib,
  ...
}: let
  devenv-mcp = lib.getExe' pkgs.devenv "devenv";
  memory-mcp = lib.getExe' pkgs.mcp-server-memory "mcp-server-memory";
in {
  programs.mcp = {
    enable = true;

    servers = {
      devenv = {
        command = devenv-mcp;
        args = [
          "mcp"
        ];
      };

      memory.command = memory-mcp;
    };
  };
}
