{...}: {
  imports = [
    ./ai

    ./astral.nix
    ./delta.nix
    ./direnv.nix
    ./gh.nix
    ./ghostty.nix
    ./git
    ./jujutsu.nix
    ./k9s.nix
    ./mullvad.nix
    ./nix-index.nix
    ./obs.nix
    ./senpai.nix
    ./tmux.nix
    ./yt-dlp.nix
    ./zk.nix
    ./zed.nix
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

    lazygit.enable = true;
    zoxide.enable = true;
  };
}
