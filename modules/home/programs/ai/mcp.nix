{
  pkgs,
  lib,
  ...
}: let
  devenv-mcp = lib.getExe' pkgs.devenv "devenv";
  markitdown-mcp = lib.getExe' pkgs.markitdown-mcp "markitdown-mcp";
  memory-mcp = lib.getExe' pkgs.mcp-server-memory "mcp-server-memory";
  nixos-mcp = lib.getExe' pkgs.mcp-nixos "mcp-nixos";
  playwright-mcp = lib.getExe' pkgs.playwright-mcp "mcp-server-playwright";
  sequential-thinking-mcp = lib.getExe' pkgs.mcp-server-sequential-thinking "mcp-server-sequential-thinking";
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

      markitdown.command = markitdown-mcp;
      memory.command = memory-mcp;
      nixos.command = nixos-mcp;
      playwright.command = playwright-mcp;
      sequential-thinking.command = sequential-thinking-mcp;
    };
  };
}
