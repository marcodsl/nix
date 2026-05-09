{
  config,
  lib,
  pkgs,
  ...
}: let
  stopHook = pkgs.writeShellApplication {
    name = "claude-stop-hook";
    runtimeInputs = with pkgs; [jq nix gnugrep coreutils];
    text = builtins.readFile ./hooks/stop.sh;
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
in {
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    context = ./CLAUDE.md;

    settings = {
      includeCoAuthoredBy = false;
      theme = "dark";
      enabledMcpjsonServers = lib.attrNames config.programs.mcp.servers;
      hooks.Stop = [
        {
          hooks = [
            {
              type = "command";
              command = lib.getExe stopHook;
            }
          ];
        }
      ];
    };

    skills = let
      mkSkillDir = path:
        lib.pipe (builtins.readDir path) [
          (lib.filterAttrs (_: type: type == "directory"))
          (lib.mapAttrs (name: _: path + "/${name}"))
        ];
    in
      (mkSkillDir config.me.ai.skills) // (mkSkillDir ./skills);

    commands = lib.pipe (builtins.readDir ./commands) [
      (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name))
      (lib.mapAttrs' (name: _: lib.nameValuePair (lib.removeSuffix ".md" name) (./commands + "/${name}")))
    ];

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
}
