{pkgs, ...}: {
  home.packages = with pkgs; [
    kubectl
    kubectx
  ];

  programs.k9s = {
    enable = true;
  };
}
