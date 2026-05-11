{
  config,
  pkgs,
  lib,
  ...
}: let
  secrets = config.sops.secrets;

  gatewayPort = 8123;

  # Each secret-bearing backend reads only its own token from sops at exec
  # time, so the gateway's env and argv (visible via /proc/<pid>/cmdline)
  # stay free of credentials.
  mkBackend = {
    name,
    runtimeInputs,
    secretEnv,
    secretPath,
    exec,
    extraExports ? "",
  }:
    lib.getExe (pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = ''
        ${extraExports}${secretEnv}="$(cat ${secretPath})"
        export ${secretEnv}
        exec ${exec}
      '';
    });

  githubBackend = mkBackend {
    name = "github-mcp-backend";
    runtimeInputs = [pkgs.github-mcp-server];
    secretEnv = "GITHUB_PERSONAL_ACCESS_TOKEN";
    secretPath = secrets."mcp/github-token".path;
    exec = "github-mcp-server stdio";
    extraExports = ''
      export GITHUB_TOOLSETS="default,actions,code_security,copilot"
    '';
  };
  todoistBackend = mkBackend {
    name = "todoist-mcp-backend";
    runtimeInputs = [pkgs.nodejs];
    secretEnv = "TODOIST_API_KEY";
    secretPath = secrets."mcp/todoist-token".path;
    exec = "npx @doist/todoist-ai";
  };
  # mcp-proxy in client mode auto-converts $API_ACCESS_TOKEN into an
  # `Authorization: Bearer <token>` header, so we pass the bearer via env
  # instead of `-H` argv.
  linearBackend = mkBackend {
    name = "linear-mcp-backend";
    runtimeInputs = [pkgs.mcp-proxy];
    secretEnv = "API_ACCESS_TOKEN";
    secretPath = secrets."mcp/linear-token".path;
    exec = "mcp-proxy --transport streamablehttp https://mcp.linear.app/mcp";
  };
  context7Backend = lib.getExe' pkgs.context7-mcp "context7-mcp";

  gateway = pkgs.writeShellApplication {
    name = "mcp-gateway";
    runtimeInputs = [pkgs.mcp-proxy];
    text = ''
      exec mcp-proxy \
        --host 127.0.0.1 --port ${toString gatewayPort} \
        --pass-environment \
        --named-server github   ${lib.escapeShellArg githubBackend} \
        --named-server todoist  ${lib.escapeShellArg todoistBackend} \
        --named-server context7 ${lib.escapeShellArg context7Backend} \
        --named-server linear   ${lib.escapeShellArg linearBackend}
    '';
  };
in {
  systemd.user.services.mcp-gateway = {
    Unit = {
      Description = "MCP gateway (mcp-proxy) — shared backends for AI clients";
      After = ["default.target" "network-online.target"];
      Wants = ["network-online.target"];
    };
    Service = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "2s";
      ExecStart = lib.getExe gateway;
    };
    Install.WantedBy = ["default.target"];
  };

  programs.mcp = {
    enable = true;
    servers = let
      url = name: {url = "http://127.0.0.1:${toString gatewayPort}/servers/${name}/mcp";};
    in {
      context7 = url "context7";
      github = url "github";
      linear = url "linear";
      todoist = url "todoist";
    };
  };
}
