{
  lib,
  pkgs,
  ...
}: {
  programs.tmux = {
    enable = true;

    aggressiveResize = true;
    baseIndex = 1;
    clock24 = true;
    customPaneNavigationAndResize = true;
    disableConfirmationPrompt = true;
    escapeTime = 0;
    focusEvents = true;
    historyLimit = 50000;
    keyMode = "vi";
    mouse = true;
    prefix = "C-a";
    secureSocket = lib.mkForce true;
    sensibleOnTop = true;
    terminal = "tmux-256color";

    plugins = with pkgs.tmuxPlugins; [
      yank
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
    ];

    extraConfig = ''
      # Truecolor for Ghostty (local) and Windows Terminal (SSH).
      set -as terminal-features ",*:RGB"

      # OSC 52 — system clipboard works through SSH without X/Wayland forwarding.
      set -g set-clipboard on

      bind R source-file ~/.config/tmux/tmux.conf \; display-message "tmux.conf reloaded"
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
    '';
  };
}
