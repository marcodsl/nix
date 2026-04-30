{pkgs, ...}: {
  home.packages = with pkgs; [
    graphrag
  ];
}
