{...}: {
  programs.delta = {
    enable = true;
    enableGitIntegration = true;

    options = {
      features = "decorations";
      dark = true;
      navigate = true;
      line-numbers = true;
      side-by-side = true;
      true-color = "always";
      whitespace-error-style = "22 reverse";
      syntax-theme = "base16-256";
      line-numbers-left-format = "";
      line-numbers-right-format = "│ ";
      plus-style = ''syntax "#003800"'';
      minus-style = ''syntax "#3f0001"'';

      decorations = {
        commit-decoration-style = "cyan bold box ul";
        file-style = "cyan bold ul";
        file-decoration-style = "cyan bold ul";
        hunk-header-decoration-style = "cyan box ul";
      };
    };
  };
}
