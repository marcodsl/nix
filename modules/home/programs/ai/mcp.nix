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
    export LINEAR_API_KEY="$(cat ${config.sops.secrets."mcp/linear-token".path})"

    ${lib.getExe' pkgs.nodejs "npx"} -y mcp-remote \
      https://mcp.linear.app/mcp \
      --header "Authorization:Bearer ''${LINEAR_API_KEY}"
  '';

  todoist = pkgs.writeShellScript "todoist-mcp-wrapper" ''
    export TODOIST_API_KEY="$(cat ${config.sops.secrets."mcp/todoist-token".path})"

    ${lib.getExe' pkgs.nodejs "npx"} @doist/todoist-ai
  '';

  context7 = lib.getExe' pkgs.context7-mcp "context7-mcp";
in {
  programs.mcp = {
    enable = true;

    servers = let
      mkServer = command: {
        inherit command;
        args = [];
        env = {};
      };
    in {
      context7 = mkServer context7;
      github = mkServer github;
      linear = mkServer linear;
      todoist = mkServer todoist;
    };
  };
}
