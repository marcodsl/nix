{config, ...}: {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      font-family = config.me.terminal.font.family;
      font-size = config.me.terminal.font.size;
    };
  };
}
