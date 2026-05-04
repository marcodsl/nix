{
  config,
  pkgs,
  lib,
  ...
}: let
  github = pkgs.writeShellScript "github-mcp-wrapper" ''
    export GITHUB_TOOLSETS="default,actions,code_security,copilot"
    export GITHUB_PERSONAL_ACCESS_TOKEN="$(cat ${config.sops.secrets."mcp/github-token".path})"
    exec ${lib.getExe pkgs.github-mcp-server} stdio
  '';

  linear = pkgs.writeShellScript "linear-mcp-wrapper" ''
    ${lib.getExe' pkgs.nodejs "npx"} -y mcp-remote \
      https://mcp.linear.app/mcp \
      --header "Authorization:Bearer $(cat ${config.sops.secrets."mcp/linear-token".path})"
  '';

  todoist = pkgs.writeShellScript "todoist-mcp-wrapper" ''
    export TODOIST_API_KEY="$(cat ${config.sops.secrets."mcp/todoist-token".path})"

    ${lib.getExe' pkgs.nodejs "npx"} @doist/todoist-ai
  '';

  context7 = lib.getExe' pkgs.context7-mcp "context7-mcp";
  markitdown = lib.getExe' pkgs.markitdown-mcp "markitdown-mcp";
in {
  programs.mcp = {
    enable = true;

    servers = {
      context7.command = context7;
      github.command = github;
      linear.command = linear;
      markitdown.command = markitdown;
      todoist.command = todoist;
    };
  };
}
