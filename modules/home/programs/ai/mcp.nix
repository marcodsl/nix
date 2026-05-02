{
  config,
  pkgs,
  lib,
  ...
}: let
  github-mcp = pkgs.writeShellScript "github-mcp-wrapper" ''
    export GITHUB_TOOLSETS="default,actions,code_security,copilot"
    export GITHUB_PERSONAL_ACCESS_TOKEN="$(cat ${config.sops.secrets."mcp/github-token".path})"
    exec ${lib.getExe pkgs.github-mcp-server} stdio
  '';

  linear-mcp = pkgs.writeShellScript "linear-mcp-wrapper" ''
    ${lib.getExe' pkgs.nodejs "npx"} -y mcp-remote \
      https://mcp.linear.app/mcp \
      --header "Authorization:Bearer $(cat ${config.sops.secrets."mcp/linear-token".path})"
  '';

  context7-mcp = lib.getExe' pkgs.context7-mcp "context7-mcp";
  markitdown-mcp = lib.getExe' pkgs.markitdown-mcp "markitdown-mcp";
in {
  programs.mcp = {
    enable = true;

    servers = {
      context7-mcp.command = context7-mcp;
      github-mcp.command = github-mcp;
      linear-mcp.command = linear-mcp;
      markitdown.command = markitdown-mcp;
    };
  };
}
