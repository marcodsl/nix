{...}: {
  programs.difftastic = {
    enable = true;
    git.enable = true;
    options = {
      background = "dark";
      display = "side-by-side";
    };
  };
}
