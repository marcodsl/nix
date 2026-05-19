{config, ...}: {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;

    # HM's systemd block re-symlinks ghostty's dbus service into
    # ~/.local/share, duplicating the copy already in the user profile and
    # making dbus-daemon log "duplicate name" on every session.
    systemd.enable = false;

    settings = {
      font-family = config.me.terminal.font.family;
      font-size = config.me.terminal.font.size;

      theme = "dark:Atom One Dark,light:Atom One Light";

      window-padding-x = 8;
      window-padding-y = 6;
      window-padding-balance = true;
      gtk-titlebar-style = "tabs";

      mouse-hide-while-typing = true;
      cursor-style-blink = false;
      copy-on-select = "clipboard";
      clipboard-trim-trailing-spaces = true;
      confirm-close-surface = false;

      shell-integration-features = "ssh-env,ssh-terminfo";
    };
  };
}
