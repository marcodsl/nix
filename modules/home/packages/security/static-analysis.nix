{pkgs, ...}: {
  home.packages = with pkgs; [
    semgrep
  ];
}
