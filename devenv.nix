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
  ];

  languages.nix.enable = true;
}
