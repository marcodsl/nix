{
  flake,
  pkgs,
  ...
}: let
  inherit (flake.inputs) self;
  system = pkgs.stdenv.hostPlatform.system;
  burpSuite = self.packages.${system}.burp-suite-pro or pkgs.burpsuite;
in {
  home.packages = with pkgs; [
    burpSuite
    caido-cli
    caido-desktop
    mitmproxy
    mitmproxy2swagger
  ];
}
