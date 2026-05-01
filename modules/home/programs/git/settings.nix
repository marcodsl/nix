{config, ...}: {
  programs.git.settings = {
    user = {
      name = config.me.fullname;
      email = config.me.email;
    };

    init.defaultBranch = "main";

    core = {
      editor = "vim";
      eol = "lf";
      whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
    };

    diff = {
      algorithm = "histogram";
      mnemonicprefix = true;
    };

    branch = {
      autosetupmerge = true;
      autosetuprebase = "always";
    };

    color.ui = "auto";
    repack.usedeltabaseoffset = true;

    push = {
      default = "current";
      followTags = true;
      autoSetupRemote = true;
    };

    pull = {
      ff = "only";
      rebase = true;
    };

    merge = {
      conflictstyle = "diff3";
      stat = true;
    };

    rebase = {
      autoSquash = true;
      autoStash = true;
    };

    rerere = {
      autoupdate = true;
      enabled = true;
    };

    url = {
      "https://github.com/".insteadOf = "github:";
      "git@github.com:arbi-ai/".insteadOf = "https://github.com/arbi-ai/";
    };
  };
}
