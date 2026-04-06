{lib, ...}: {
  programs.tmux = {
    enable = true;

    focusEvents = true;
    keyMode = "vi";
    mouse = true;
    secureSocket = lib.mkForce true;
  };
}
