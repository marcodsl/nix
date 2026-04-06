{...}: {
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;

    nix-direnv.enable = true;

    config = {
      global = {
        warn_timeout = "60s";
        hide_env_diff = true;
      };
    };
  };
}
