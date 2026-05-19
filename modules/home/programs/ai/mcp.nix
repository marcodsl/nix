{
  config,
  pkgs,
  lib,
  ...
}: let
  secrets = config.sops.secrets;

  gatewayPort = 8123;

  # Each secret-bearing backend reads only its own token at exec time, so
  # the gateway's env and argv (visible via /proc/<pid>/cmdline) stay
  # credential-free.
  mkBackend = {
    name,
    runtimeInputs,
    exec,
    secretEnv,
    secretKey,
    env ? {},
  }:
    lib.getExe (pkgs.writeShellApplication {
      name = "${name}-mcp-backend";
      inherit runtimeInputs;
      text = ''
        ${lib.concatMapAttrsStringSep "\n" (k: v: "export ${k}=${lib.escapeShellArg v}") env}
        ${secretEnv}="$(cat ${secrets."mcp/${secretKey}".path})"
        export ${secretEnv}
        exec ${exec}
      '';
    });

  # mcp-proxy in client mode auto-converts $API_ACCESS_TOKEN into an
  # `Authorization: Bearer <token>` header.
  mkProxyBackend = name: url: secretKey:
    mkBackend {
      inherit name secretKey;
      runtimeInputs = [pkgs.mcp-proxy];
      secretEnv = "API_ACCESS_TOKEN";
      exec = "mcp-proxy --transport streamablehttp ${url}";
    };

  backends = {
    github = mkBackend {
      name = "github";
      runtimeInputs = [pkgs.github-mcp-server];
      secretEnv = "GITHUB_PERSONAL_ACCESS_TOKEN";
      secretKey = "github-token";
      exec = "github-mcp-server stdio";
      env.GITHUB_TOOLSETS = "default,actions,code_security,copilot";
    };
    todoist = mkBackend {
      name = "todoist";
      runtimeInputs = [pkgs.nodejs];
      secretEnv = "TODOIST_API_KEY";
      secretKey = "todoist-token";
      exec = "npx @doist/todoist-ai";
    };
    context7 = lib.getExe' pkgs.context7-mcp "context7-mcp";
    linear = mkProxyBackend "linear" "https://mcp.linear.app/mcp" "linear-token";
    betterstack = mkProxyBackend "betterstack" "https://mcp.betterstack.com" "betterstack-token";
  };

  gateway = pkgs.writeShellApplication {
    name = "mcp-gateway";
    runtimeInputs = [pkgs.mcp-proxy];
    # --pass-environment forwards the gateway's env to every backend; never
    # add Environment= to the unit below — anything there leaks to all five.
    text = ''
      exec mcp-proxy \
        --host 127.0.0.1 --port ${toString gatewayPort} \
        --pass-environment \
        ${lib.concatMapStringsSep " \\\n  "
        (n: "--named-server ${n} ${lib.escapeShellArg backends.${n}}")
        (lib.attrNames backends)}
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
      MemoryHigh = "2G";
      MemoryMax = "3G";
      TasksMax = 512;
    };
    Install.WantedBy = ["default.target"];
  };

  programs.mcp = {
    enable = true;
    servers =
      lib.mapAttrs
      (name: _: {url = "http://127.0.0.1:${toString gatewayPort}/servers/${name}/mcp";})
      backends;
  };
}
