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
      fsmonitor = true;
      untrackedCache = true;
    };

    diff = {
      algorithm = "histogram";
      mnemonicprefix = true;
      colorMoved = "zebra";
      colorMovedWS = "allow-indentation-change";
    };

    branch = {
      autosetupmerge = true;
      autosetuprebase = "always";
      sort = "-committerdate";
    };

    tag.sort = "version:refname";

    color.ui = "auto";
    column.ui = "auto";
    repack.usedeltabaseoffset = true;

    commit.verbose = true;
    help.autocorrect = "prompt";

    push = {
      default = "current";
      followTags = true;
      autoSetupRemote = true;
      useForceIfIncludes = true;
    };

    pull = {
      ff = "only";
      rebase = true;
    };

    fetch = {
      prune = true;
      pruneTags = true;
      fsckObjects = true;
    };

    transfer.fsckObjects = true;
    receive.fsckObjects = true;

    merge = {
      conflictStyle = "zdiff3";
      stat = true;
    };

    rebase = {
      autoSquash = true;
      autoStash = true;
      updateRefs = true;
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

  # Conditional includes: split work/personal identity by repo location.
  # Uncomment and adjust paths/keys when needed:
  # programs.git.includes = [
  #   {
  #     condition = "gitdir:~/work/";
  #     contents.user.email = "marco@work.example";
  #     # contents.user.signingkey = "~/.ssh/id_ed25519_work.pub";
  #   }
  # ];
}
