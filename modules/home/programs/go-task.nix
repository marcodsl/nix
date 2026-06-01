{lib, ...}: {
  programs.zsh.initContent = lib.mkAfter ''
    if command -v task > /dev/null 2>&1; then
      eval "$(task --completion zsh)"
    fi
  '';
}
