{
  config,
  pkgs,
  lib,
  ...
}: {
  programs = {
    bash = {
      # on macOS, we probably don't need this
      enable = pkgs.stdenv.hostPlatform.isLinux;
      initExtra = ''
        # Custom bash profile goes here
      '';
    };

    # For macOS's default shell.
    zsh = let
      sessionPath = [
        "$HOME/.local/bin"
      ];
    in {
      enable = true;

      autosuggestion = {
        enable = true;
      };

      syntaxHighlighting.enable = true;

      shellAliases = {
        docker = "podman";
      };

      envExtra = ''
        # Custom ~/.zshenv goes here
      '';

      profileExtra = ''
        ${lib.concatMapStringsSep "\n" (p: "export PATH=\"${p}:$PATH\"") sessionPath}
        export PATH="$HOME/.nix-profile/bin:$PATH"
      '';

      loginExtra = ''
        # Custom ~/.zlogin goes here
      '';

      logoutExtra = ''
        # Custom ~/.zlogout goes here
      '';

      dotDir = "${config.xdg.configHome}/zsh";
    };

    starship = {
      enable = true;

      settings = {
        username = {
          style_user = "blue bold";
          style_root = "red bold";
          format = "[$user]($style) ";
          disabled = false;
          show_always = true;
        };

        hostname = {
          ssh_only = false;
          ssh_symbol = "🌐 ";
          format = "on [$hostname](bold red) ";
          trim_at = ".local";
          disabled = false;
        };
      };
    };
  };
}
