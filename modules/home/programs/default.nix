{...}: {
  imports = [
    ./ai

    ./delta.nix
    ./direnv.nix
    ./gh.nix
    ./ghostty.nix
    ./git.nix
    ./jujutsu.nix
    ./k9s.nix
    ./nix-index.nix
    ./obs.nix
    ./tmux.nix
    ./uv.nix
    ./yt-dlp.nix
    ./zk.nix
  ];

  programs = {
    bat = {
      enable = true;
      config.pager = "less -FR";
    };

    btop.enable = true;

    dircolors.enable = true;
    eza.enable = true;
    fastfetch.enable = true;
    fd.enable = true;
    fzf.enable = true;
    jq.enable = true;

    ripgrep = {
      enable = true;
      arguments = [
        "--max-columns=150"
        "--max-columns-preview"
        "--glob=!.git/*"
        "--smart-case"
      ];
    };

    man.enable = true;
    pandoc.enable = true;
    # If Linux
    # sagemath.enable = pkgs.stdenv.isLinux;
    senpai.enable = false; # TODO: setup secret management before enabling

    lazygit.enable = true;
    zoxide.enable = true;
  };
}
