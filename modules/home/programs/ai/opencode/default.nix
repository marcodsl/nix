# SPDX-License-Identifier: AGPL-3.0-only
{...}: {
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;

    skills = {
      coding-guidelines = ./skills/coding-guidelines;
      natural-tone = ./skills/natural-tone;
      prompt-engineering = ./skills/prompt-engineering;
    };

    rules = ./AGENTS.md;

    settings = {
      autoupdate = "notify";
      compaction.reserved = 33000;

      instructions = [
        ./instructions/mcp-memory.md
      ];

      plugin = [
        "opencode-workspace"
      ];

      watcher.ignore = [
        ".git/**"
        ".jj/**"
        ".direnv/**"
        ".devenv/**"
        ".next/**"
        ".nuxt/**"
        ".svelte-kit/**"
        ".astro/**"
        ".turbo/**"
        ".cache/**"
        ".venv/**"
        ".pytest_cache/**"
        ".mypy_cache/**"
        ".ruff_cache/**"
        "__pycache__/**"
        "node_modules/**"
        "target/**"
        "build/**"
        "dist/**"
        "coverage/**"
        "out/**"
        "tmp/**"
        "result"
        "result-*"
      ];

      permission = {
        "*" = "ask";

        read = {
          "*" = "allow";
          "*.env" = "deny";
          "*.env.*" = "deny";
          "*.env.example" = "allow";
        };

        list = "allow";
        glob = "allow";
        grep = "allow";
        lsp = "allow";
        skill = "allow";
        question = "allow";

        webfetch = "ask";
        external_directory = "ask";

        bash = {
          "*" = "ask";

          "git status" = "allow";
          "git status *" = "allow";
          "git diff" = "allow";
          "git diff *" = "allow";
          "git log" = "allow";
          "git log *" = "allow";
          "git show" = "allow";
          "git show *" = "allow";
          "git rev-parse" = "allow";
          "git rev-parse *" = "allow";
          "git ls-files" = "allow";
          "git ls-files *" = "allow";

          "grep" = "allow";
          "grep *" = "allow";
          "rg" = "allow";
          "rg *" = "allow";
          "fd" = "allow";
          "fd *" = "allow";
          "find" = "allow";
          "find *" = "allow";

          "git add" = "deny";
          "git add *" = "deny";
          "git commit" = "deny";
          "git commit *" = "deny";
          "git push" = "deny";
          "git push *" = "deny";
          "git pull" = "deny";
          "git pull *" = "deny";
          "git merge" = "deny";
          "git merge *" = "deny";
          "git rebase" = "deny";
          "git rebase *" = "deny";
          "git cherry-pick" = "deny";
          "git cherry-pick *" = "deny";
          "git reset" = "deny";
          "git reset *" = "deny";
          "git checkout" = "deny";
          "git checkout *" = "deny";
          "git switch" = "deny";
          "git switch *" = "deny";
          "git restore" = "deny";
          "git restore *" = "deny";
          "git clean" = "deny";
          "git clean *" = "deny";
          "git stash" = "deny";
          "git stash *" = "deny";

          "rm" = "ask";
          "rm *" = "ask";
          "rmdir" = "ask";
          "rmdir *" = "ask";
          "shred" = "ask";
          "shred *" = "ask";
          "sudo" = "ask";
          "sudo *" = "ask";
        };
      };
    };
  };
}
