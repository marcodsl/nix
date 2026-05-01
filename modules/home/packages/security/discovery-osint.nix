{pkgs, ...}: {
  home.packages = with pkgs; [
    amass
    maltego
    sn0int
    subfinder
  ];
}
