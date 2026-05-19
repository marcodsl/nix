{pkgs, ...}: {
  programs.gh = {
    enable = true;

    extensions = with pkgs; [
      gh-poi
      gh-markdown-preview
    ];
  };
}
