{config, ...}: {
  programs.zk = {
    enable = false;
    settings = {
      notebook.dir = "${config.home.homeDirectory}/.zk";

      note = {
        language = "en";

        default-title = "Untitled";
        filename = "{{title}}";
        extension = "md";
        template = "default.md";

        id-charset = "hex";
        id-length = 8;
        id-case = "lower";
      };

      extra = {
        author = "Marco";
      };

      format.markdown.link-format = "[[{{filename}}]]";

      tool = {
        editor = "code --wait";
        fzf-preview = "bat -p --color always {-1}";
      };

      lsp.diagnostics = {
        wiki-title = "hint";
        dead-link = "error";
      };
    };
  };
}
