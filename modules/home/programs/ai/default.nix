# SPDX-License-Identifier: AGPL-3.0-only
{...}: {
  imports = [
    ./claude
    ./codex
    ./copilot
    ./graphrag.nix

    ./mcp.nix
  ];
}
