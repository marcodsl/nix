# Source of truth for this repo's devenv packages and options.
# `nix develop --no-pure-eval` loads this file through `modules/flake/devshell.nix`.
# Direct `devenv` commands read it alongside `devenv.yaml` and `devenv.lock`.
{pkgs, ...}: {
  packages = with pkgs; [
    age
    alejandra
    git
    just
    just-lsp
    nil
    sops
    zip
  ];

  languages.python = {
    enable = true;
    uv.enable = true;
  };

  languages.nix.enable = true;

  # Nested `nix-shell` inherits exported environment variables from the active
  # devenv shell. Dropping `shellHook` after activation prevents child shells
  # from re-running the parent devenv hook without its DEVENV_* context.
  unsetEnvVars = ["shellHook"];
}
