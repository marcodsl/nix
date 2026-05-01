{pkgs, ...}: {
  home.packages = with pkgs; [
    lynis
    vulnix
  ];
}
