{
  config,
  flake,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) escapeShellArg getExe mapAttrs optionalAttrs;

  cfg = config.programs.codex;
  tomlFormat = pkgs.formats.toml {};

  # Match the upstream programs.codex.enableMcpIntegration transform so the
  # generated mcp_servers section is identical to what enableMcpIntegration
  # would have produced — minus the read-only nix-store symlink.
  mkMcpServer = _name: server:
    (builtins.removeAttrs server ["disabled" "headers"])
    // optionalAttrs (server ? headers && !(server ? http_headers)) {
      http_headers = server.headers;
    }
    // {
      enabled = !(server.disabled or false);
    };

  transformedMcpServers =
    optionalAttrs (cfg.enableMcpIntegration && config.programs.mcp.enable)
    (mapAttrs mkMcpServer config.programs.mcp.servers);

  settingMcpServers = cfg.settings.mcp_servers or {};
  mergedMcpServers = transformedMcpServers // settingMcpServers;

  # Match the upstream module's `mergedSettings`: user-provided
  # `programs.codex.settings` plus auto-generated MCP servers, with
  # settings-defined servers taking precedence over transformed shared ones.
  nixManagedConfig =
    cfg.settings
    // optionalAttrs (mergedMcpServers != {}) {
      mcp_servers = mergedMcpServers;
    };

  nixStateFile = tomlFormat.generate "codex-nix-state.toml" nixManagedConfig;

  # Re-derive the codex_home path the same way the upstream module does, so
  # we land the writable config.toml at exactly the location codex looks for.
  useXdgDirectories = config.home.preferXdgDirectories or false;
  xdgConfigHome = lib.removePrefix config.home.homeDirectory config.xdg.configHome;
  codexHomeRel =
    if useXdgDirectories
    then "${xdgConfigHome}/codex"
    else ".codex";
  codexHomeAbs = "${config.home.homeDirectory}/${codexHomeRel}";
  userConfigPath = "${codexHomeAbs}/config.toml";
  prevStatePath = "${codexHomeAbs}/.nix-managed.toml";

  # Three-way merge at top-level granularity: apply current Nix keys, drop
  # keys the previous snapshot owned but the new one doesn't, leave the rest
  # alone so Codex's runtime writes (theme, app state, ...) survive
  # activation.
  mergeScript = flake.self.lib.mkSettingsMerge pkgs {
    name = "codex-config-merge";
    format = "toml";
    deep = false;
  };
in {
  home.packages = [pkgs.codex];

  programs.codex = {
    enable = true;
    skills = config.me.ai.skills;
    # `programs.codex.settings` and `programs.codex.enableMcpIntegration`
    # may still be set by the user; both feed `nixManagedConfig` above.
    # We do NOT let the upstream module materialise config.toml itself —
    # Codex needs that file writable (theme, feature flags, app state,
    # etc. are persisted via writes to it). The override below disables
    # the upstream `home.file` entry; the activation script writes the
    # equivalent content as a regular file.
  };

  # Defeat the upstream `home.file."<codex_home>/config.toml"` entry
  # (which would symlink to a read-only nix-store path).
  home.file."${codexHomeRel}/config.toml".enable = lib.mkForce false;

  home.activation.mergeCodexConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${getExe mergeScript} \
      --state ${nixStateFile} \
      --prev-state ${escapeShellArg prevStatePath} \
      --user ${escapeShellArg userConfigPath}
  '';
}
