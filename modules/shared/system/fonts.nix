{pkgs, ...}: {
  fonts.packages = with pkgs;
    (with nerd-fonts; [
      blex-mono
      geist-mono
      iosevka
      iosevka-term
      iosevka-term-slab
      jetbrains-mono
      monaspace
      symbols-only
      tinos
      zed-mono
    ])
    ++ (
      with ioskeley-mono; [
        normal-NF
      ]
    )
    ++ [
      inter
      work-sans
      googlesans-code
      dm-sans
    ];
}
