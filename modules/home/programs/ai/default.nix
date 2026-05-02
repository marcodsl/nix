# SPDX-License-Identifier: AGPL-3.0-only
{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./claude
    ./codex
    ./copilot

    ./mcp.nix
  ];

  options = {
    me.ai.skills = lib.mkOption {
      type = lib.types.path;
      description = "Path to the skills directory.";
      default = ./skills;
    };
  };

  config = {
    home.packages = with pkgs; [
      graphrag
      skills-ref
    ];
  };
}
