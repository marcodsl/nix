{
  config,
  lib,
  ...
}: {
  home.sessionVariables.SSH_AUTH_SOCK = "${config.home.homeDirectory}/.1password/agent.sock";

  programs.ssh = {
    enable = true;
    matchBlocks."*".extraOptions.IdentityAgent = "~/.1password/agent.sock";
  };

  programs.zsh.initContent = lib.mkAfter ''
    if command -v op > /dev/null 2>&1; then
      eval "$(op completion zsh)"
    fi
  '';
}
