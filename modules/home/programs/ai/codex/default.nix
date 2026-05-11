{
  config,
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

  mcpEnabled =
    (config.programs.mcp.enable or false)
    && (config.programs.mcp.servers or {}) != {};

  generatedMcpServers =
    optionalAttrs mcpEnabled
    (mapAttrs mkMcpServer config.programs.mcp.servers);

  # Match the upstream module's `mergedSettings`: user-provided
  # `programs.codex.settings` plus the auto-generated MCP servers.
  nixManagedConfig =
    (cfg.settings or {})
    // optionalAttrs (generatedMcpServers != {}) {
      mcp_servers = generatedMcpServers;
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
  # alone so Codex's runtime writes (theme, app state, …) survive activation.
  mergeScript =
    pkgs.writers.writePython3Bin "codex-config-merge" {
      libraries = [pkgs.python3Packages.tomli-w];
      flakeIgnore = ["E501"];
    } ''
      import os
      import sys
      import tomllib
      import tomli_w
      from pathlib import Path

      nix_state_path, prev_state_path, user_path = (
          Path(p) for p in sys.argv[1:4]
      )


      def load_toml(p):
          if not p.exists():
              return {}
          return tomllib.loads(p.read_text())


      def write_toml(p, data):
          if p.is_symlink():
              p.unlink()
          p.parent.mkdir(parents=True, exist_ok=True)
          tmp = p.with_name(p.name + ".tmp")
          tmp.write_text(tomli_w.dumps(data))
          os.replace(tmp, p)


      nix_state = load_toml(nix_state_path)
      prev_state = load_toml(prev_state_path)
      user_config = load_toml(user_path)

      # Apply: every key Nix currently manages.
      for key, value in nix_state.items():
          user_config[key] = value

      # Remove: keys Nix used to manage but no longer does.
      for key in set(prev_state) - set(nix_state):
          user_config.pop(key, None)

      write_toml(user_path, user_config)
      write_toml(prev_state_path, nix_state)
    '';
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
      ${nixStateFile} \
      ${escapeShellArg prevStatePath} \
      ${escapeShellArg userConfigPath}
  '';
}
