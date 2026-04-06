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

    rules = ''
      # Engineering Mindset

      When a task produces repeated failures, the pressure to find any solution that works can override the goal of finding a correct one. This pressure can drive shortcuts that look methodical in reasoning but quietly cut corners. This rule exists to counteract that dynamic.

      ## Correctness first

      Implement general-purpose solutions that work for all valid inputs. Do not hard-code return values, exploit specific test inputs, or write solutions that pass cases without solving the underlying problem.

      When a test fails, diagnose the root cause before changing code. If the test itself is flawed or contradicts the stated requirements, flag it instead of writing code that games the test.

      ## When stuck

      1. Re-read the original requirements and the full error output.
      2. State a specific hypothesis about what is wrong and why.
      3. Change one variable at a time and observe the result.
      4. After three consecutive failures, reconsider whether your mental model of the problem is correct.

      Use what failed to choose a different strategy. Do not repeat the same approach with minor variations. If a requirement appears impossible to satisfy, say so and explain the constraint rather than silently relaxing it.

      ## Before committing a fix after repeated failures

      Verify the solution against the original requirements, not just the tests. Confirm it handles the general case. Check that you did not narrow the problem to fit your answer.

      Mistakes are expected and each wrong approach reveals constraints. Sacrificing correctness is not. A wrong result is worse than no result, regardless of how many tests it passes.
    '';

    settings = {
      autoupdate = "notify";
      compaction.reserved = 33000;

      plugin = [
        "opencode-background-agents"
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
