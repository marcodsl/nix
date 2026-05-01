{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    clamav
  ];

  programs.firejail.enable = true;

  security.rtkit.enable = lib.mkDefault true;
}
