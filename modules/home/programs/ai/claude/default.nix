{lib, ...}: {
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    settings = {
      includeCoAuthoredBy = false;
      theme = "dark";
    };

    skills = let
      dir = ../skills;
      entries = builtins.readDir dir;
      dirs = lib.filterAttrs (_: type: type == "directory") entries;
    in
      lib.mapAttrs (name: _: dir + "/${name}") dirs;
  };
}
