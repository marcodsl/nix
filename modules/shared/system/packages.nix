{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Nix
    alejandra
    nil
    nix-output-monitor
    nvd

    # Secrets
    age
    sops

    # Version control
    git

    # Shell utilities
    curl
    fd
    just
    jq
    ripgrep
    rsync
    vim
    wget

    # System diagnostics
    lsof
    strace

    # Network diagnostics
    dnsutils
    ethtool
    tcpdump
    traceroute

    # Hardware diagnostics
    lshw
    pciutils
    smartmontools
    usbutils

    # Applications
    vscode
  ];
}
