{pkgs, ...}: {
  home.packages = with pkgs; [
    rustscan
    nmap
    naabu
    fingerprintx
    httpx
    katana
  ];
}
