{pkgs, ...}: let
  wordlists = pkgs.wordlists.override {
    lists = with pkgs; [
      rockyou
      seclists
    ];
  };
in {
  home.packages = [wordlists];
}
