{pkgs, ...}: {
  fonts.packages = with pkgs;
    (with nerd-fonts; [
      geist-mono
      iosevka
      jetbrains-mono
      monaspace
      symbols-only
      zed-mono
    ])
    ++ [
      inter
    ];
}
