{
  config,
  pkgs,
  ...
}: {
  programs.gh = {
    enable = true;

    extensions = with pkgs; [
      gh-poi
      gh-markdown-preview
    ];

    hosts = {
      "github.com" = {
        user = config.me.github.username;
      };
    };

    settings = {
      editor = "nvim";
      prompt = "enabled";
      pager = "less -FR";
    };
  };
}
