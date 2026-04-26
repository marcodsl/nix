{
  flake,
  pkgs,
  lib,
  ...
}: let
  inherit (flake.inputs) self;

  system = pkgs.stdenv.hostPlatform.system;
in {
  programs.mcp = {
    enable = true;

    servers = let
      context-mode = lib.getExe' self.packages.${system}.context-mode "context-mode";
      markitdown-mcp = lib.getExe' pkgs.markitdown-mcp "markitdown-mcp";
      nixos-mcp = lib.getExe' pkgs.mcp-nixos "mcp-nixos";
      sequential-thinking-mcp = lib.getExe' pkgs.mcp-server-sequential-thinking "mcp-server-sequential-thinking";
    in {
      context-mode.command = context-mode;
      markitdown.command = markitdown-mcp;
      nixos.command = nixos-mcp;
      sequential-thinking.command = sequential-thinking-mcp;
    };
  };
}
