{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    alejandra
    curl
    git
    just
    nil
    rsync
    vim
    vscode
    wget
  ];
}
