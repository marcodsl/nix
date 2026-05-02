{lib, ...}: {
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    context = ./CLAUDE.md;

    settings = {
      includeCoAuthoredBy = false;
      theme = "dark";
    };

    skills = lib.pipe (builtins.readDir ../skills) [
      (lib.filterAttrs (_: type: type == "directory"))
      (lib.mapAttrs (name: _: ../skills + "/${name}"))
    ];
  };
}
