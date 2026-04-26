{...}: {
  editorconfig = {
    enable = true;

    settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        insert_final_newline = true;
        trim_trailing_whitespace = true;

        max_line_length = 100;

        indent_style = "space";
        indent_size = 2;
      };

      "*.md" = {
        trim_trailing_whitespace = false;
        max_line_length = "off";
      };

      "*.{sh,bash}".max_line_length = 80;
      "*.py".max_line_length = 88;
      "*.rs".indent_size = 4;

      "{justfile,*.just}".indent_size = 4;

      "{Makefile,makefile,*.mk}" = {
        indent_style = "tab";
        indent_size = "4";
      };
    };
  };
}
