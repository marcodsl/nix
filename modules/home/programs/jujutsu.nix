{config, ...}: {
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = config.me.fullname;
        email = config.me.email;
      };
    };
  };
}
