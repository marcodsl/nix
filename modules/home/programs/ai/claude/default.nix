{
  config,
  flake,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  stopHook = pkgs.writeShellApplication {
    name = "claude-stop-hook";
    runtimeInputs = [
      pkgs.jq
      pkgs.nix
      pkgs.gnugrep
      pkgs.coreutils
      flake.self.packages.${pkgs.stdenv.hostPlatform.system}.skills-ref
    ];
    text = builtins.readFile ./hooks/stop.sh;
  };

  otelHeadersHelper = pkgs.writeShellApplication {
    name = "claude-otel-headers";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      token="$(cat ${config.sops.secrets."betterstack/claude_source_token".path})"
      printf '{"Authorization":"Bearer %s"}\n' "$token"
    '';
  };

  pushoverHook = pkgs.writeShellApplication {
    name = "claude-pushover-hook";
    runtimeInputs = [pkgs.curl pkgs.jq pkgs.coreutils pkgs.inetutils];
    text = ''
      export PUSHOVER_TOKEN_FILE=${config.sops.secrets."pushover/api_token".path}
      export PUSHOVER_USER_FILE=${config.sops.secrets."pushover/user_key".path}
      ${builtins.readFile ./hooks/pushover-notify.sh}
    '';
  };

  # Claude reads the OTEL exporter endpoint from its own process env; the URL
  # is tenant-identifying so it's kept in sops and sourced at launch time.
  claudeWrapped = pkgs.symlinkJoin {
    name = "claude-code-otel-wrapped";
    paths = [pkgs.claude-code];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/claude \
        --run 'set -a; . ${config.sops.templates."claude-otel.env".path}; set +a'
    '';
  };

  mkClaudeAgent = {
    name,
    description,
    model ? "inherit",
    disallowedTools ? ["Bash" "Edit"],
    permissionMode ? "dontAsk",
    prompt,
  }: ''
    ---
    name: ${name}
    description: ${description}
    model: ${model}
    disallowedTools: ${builtins.concatStringsSep ", " disallowedTools}
    permissionMode: ${permissionMode}
    ---
    ${prompt}
  '';

  telemetryHostName =
    if osConfig != null
    then osConfig.networking.hostName
    else config.home.username;

  nixManagedSettings = {
    # Mirrors the $schema key the upstream module would have injected,
    # so editors keep validating after we suppress its symlink.
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";

    theme = "dark";

    attribution = {
      commit = "";
      pr = "";
    };

    showThinkingSummaries = true;
    skillListingBudgetFraction = 0.03;

    spinnerTipsEnabled = false;
    includeGitInstructions = false;
    cleanupPeriodDays = 20;

    forceLoginMethod = "claudeai";
    language = "english";
    useAutoModeDuringPlan = true;

    permissions.disableBypassPermissionsMode = "disable";

    teammateMode = "auto";

    worktree.symlinkDirectories = [
      "node_modules"
      ".envrc"
      ".direnv"
      ".env"
      ".env.local"
      ".CLAUDE.md"
      ".claude"
      ".vscode"
    ];

    otelHeadersHelper = lib.getExe otelHeadersHelper;

    # OTEL_EXPORTER_OTLP_*_ENDPOINT come from the sops-rendered
    # claude-otel.env, sourced by the wrapper above.
    env = {
      CLAUDE_CODE_ENABLE_TELEMETRY = "1";
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      CLAUDE_CODE_ENHANCED_TELEMETRY_BETA = "1";

      OTEL_METRICS_EXPORTER = "otlp";
      OTEL_LOGS_EXPORTER = "otlp";
      OTEL_TRACES_EXPORTER = "otlp";

      OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf";
      OTEL_EXPORTER_OTLP_COMPRESSION = "gzip";

      OTEL_METRIC_EXPORT_INTERVAL = "30000";
      OTEL_METRICS_INCLUDE_VERSION = "true";
      OTEL_LOG_TOOL_DETAILS = "1";
      OTEL_RESOURCE_ATTRIBUTES = "host.name=${telemetryHostName}";
    };

    enabledMcpjsonServers = lib.attrNames config.programs.mcp.servers;
    hooks = {
      Stop = [
        {
          hooks = [
            {
              type = "command";
              command = lib.getExe stopHook;
            }
          ];
        }
      ];
      Notification = [
        {
          matcher = "permission_prompt|idle_prompt|elicitation_dialog";
          hooks = [
            {
              type = "command";
              command = lib.getExe pushoverHook;
              async = true;
              timeout = 10;
            }
          ];
        }
      ];
    };
  };

  jsonFormat = pkgs.formats.json {};
  nixStateFile = jsonFormat.generate "claude-nix-state.json" nixManagedSettings;

  # Upstream `programs.claude-code` hard-codes `.claude/`, so no XDG branch.
  claudeHomeRel = ".claude";
  claudeHomeAbs = "${config.home.homeDirectory}/${claudeHomeRel}";
  userSettingsPath = "${claudeHomeAbs}/settings.json";
  prevStatePath = "${claudeHomeAbs}/.nix-managed.json";

  # Deep recursive merge: nix-declared keys overwrite user values at every
  # depth; keys nix no longer declares are removed; sibling keys claude
  # writes at runtime (or the user adds by hand) survive untouched.
  # Lists are overwritten wholesale; deep list merge is intentionally out
  # of scope.
  mergeScript = flake.self.lib.mkSettingsMerge pkgs {
    name = "claude-settings-merge";
    format = "json";
    deep = true;
  };
in {
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
    package = claudeWrapped;

    context = ./CLAUDE.md;

    settings = nixManagedSettings;

    skills = let
      mkSkillDir = path:
        lib.pipe (builtins.readDir path) [
          (lib.filterAttrs (_: type: type == "directory"))
          (lib.mapAttrs (name: _: path + "/${name}"))
        ];
    in
      (mkSkillDir config.me.ai.skills) // (mkSkillDir ./skills);

    commandsDir = ./commands;

    agents = {
      researcher = mkClaudeAgent {
        name = "researcher";
        description = "Research subagent that executes thorough searches based on main agent instructions. Searches GitHub repos, fetches files, verifies claims, and reports detailed findings with citations. Designed to work autonomously within a research workflow.";
        disallowedTools = ["Bash" "Edit"];
        prompt = builtins.readFile ./agents/researcher.md;
      };

      security-reviewer = mkClaudeAgent {
        name = "security-reviewer";
        description = "Security-focused code review subagent for the consensus-review pipeline. Scans a captured git diff for exploitable vulnerabilities (injection sinks, authn/authz gaps, unsafe crypto, deserialization, SSRF, etc.) and returns JSON findings with mandatory file:line citations and minimal patches. Read-only — does not modify files.";
        disallowedTools = ["Edit" "Write"];
        prompt = builtins.readFile ./agents/security-reviewer.md;
      };

      simplicity-reviewer = mkClaudeAgent {
        name = "simplicity-reviewer";
        description = "Simplicity and dead-code review subagent for the consensus-review pipeline. Scans a captured git diff for unused exports, unreachable branches, vestigial flags, and over-abstraction introduced by the diff. Returns JSON findings with mandatory file:line citations and minimal removal patches. Read-only — does not modify files.";
        disallowedTools = ["Edit" "Write"];
        prompt = builtins.readFile ./agents/simplicity-reviewer.md;
      };

      type-correctness-reviewer = mkClaudeAgent {
        name = "type-correctness-reviewer";
        description = "Type-correctness review subagent for the consensus-review pipeline. Scans a captured git diff for type holes, unsafe casts, mismatched signatures, nullable handling, and non-exhaustive matches that the language's type checker may miss. Returns JSON findings with mandatory file:line citations and minimal patches. Read-only — does not modify files.";
        disallowedTools = ["Edit" "Write"];
        prompt = builtins.readFile ./agents/type-correctness-reviewer.md;
      };

      test-coverage-reviewer = mkClaudeAgent {
        name = "test-coverage-reviewer";
        description = "Test-coverage review subagent for the consensus-review pipeline. Scans a captured git diff for new code paths without tests, missing edge cases, missing regression tests, and flaky test patterns. Returns JSON findings with mandatory file:line citations and patches that add or extend tests. Read-only — does not modify files.";
        disallowedTools = ["Edit" "Write"];
        prompt = builtins.readFile ./agents/test-coverage-reviewer.md;
      };

      api-contract-reviewer = mkClaudeAgent {
        name = "api-contract-reviewer";
        description = "API and contract consistency review subagent for the consensus-review pipeline. Scans a captured git diff for naming inconsistencies, error-shape parity violations, breaking public-surface changes, and missing deprecation paths. Returns JSON findings with mandatory file:line citations and minimal patches. Read-only — does not modify files.";
        disallowedTools = ["Edit" "Write"];
        prompt = builtins.readFile ./agents/api-contract-reviewer.md;
      };

      review-synthesizer = mkClaudeAgent {
        name = "review-synthesizer";
        description = "Synthesis subagent for the consensus-review pipeline. Receives reviewer JSON outputs and a captured git diff; deduplicates findings, verifies each cited location is grounded against the actual files (rejects hallucinations), decides qualification, groups patches by file-set with dependency ordering, and emits a JSON apply plan. Read-only — does not apply patches, run tests, or modify state.";
        disallowedTools = ["Bash" "Edit" "Write"];
        prompt = builtins.readFile ./agents/review-synthesizer.md;
      };
    };
  };

  # Upstream symlinks settings.json to a read-only /nix/store path; claude
  # needs to write runtime preferences into it, so suppress the symlink and
  # let the activation script below materialise a regular file instead.
  home.file."${userSettingsPath}".enable = lib.mkForce false;

  home.activation.mergeClaudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${lib.getExe mergeScript} \
      --state ${nixStateFile} \
      --prev-state ${lib.escapeShellArg prevStatePath} \
      --user ${lib.escapeShellArg userSettingsPath}
  '';
}
