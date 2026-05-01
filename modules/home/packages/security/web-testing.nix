{pkgs, ...}: {
  home.packages = with pkgs; [
    feroxbuster
    ffuf
    nikto
    nuclei
    nuclei-templates
    sqlmap
    wapiti
    wpscan
  ];
}
