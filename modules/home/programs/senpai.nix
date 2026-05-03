{config, ...}: {
  programs.senpai = {
    enable = true;

    config = {
      address = "irc.libera.chat:6697";
      nickname = "marcodsl";
      password-cmd = ["cat" config.sops.secrets."senpai/password".path];
    };
  };
}
