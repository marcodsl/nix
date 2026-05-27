{lib, ...}: {
  # https://devenv.sh/auto-activation/
  # Auto-activate the devenv shell when entering a directory with a `devenv.yaml`
  # that has been trusted via `devenv allow`. Per-project trust keeps this opt-in;
  # this repo intentionally stays direnv-driven via `.envrc`.
  programs.zsh.initContent = lib.mkAfter ''
    eval "$(devenv hook zsh)"
  '';
}
