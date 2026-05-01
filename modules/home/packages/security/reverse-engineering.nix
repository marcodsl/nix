{pkgs, ...}: let
  ghidra = pkgs.ghidra.withExtensions (extensions:
    with extensions; [
      findcrypt
      kaiju
      machinelearning
      ret-sync
      wasm
    ]);
in {
  home.packages = with pkgs; [
    detect-it-easy
    flare-floss
    ghidra
    imhex
    pe-bear
    volatility3
  ];
}
