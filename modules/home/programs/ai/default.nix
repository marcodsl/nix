# SPDX-License-Identifier: AGPL-3.0-only
{pkgs, ...}: {
  imports = [
    ./claude
    ./codex
    ./copilot

    ./mcp.nix
  ];

  config = {
    home.packages = [
      pkgs.graphrag
    ];
  };
}
