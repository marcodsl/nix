{
  lib,
  pkgs,
  ...
}: let
  # Keep this list focused on host-specific additions.
  # nix-ld already provides its own default compatibility libraries upstream.
  graphicalCompatibilityLibraries = with pkgs; [
    libelf
    libGL
    libva
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxshmfence
    libxtst
    libxxf86vm
    pipewire
  ];

  requiredRuntimeLibraries = with pkgs; [
    glib
    gtk2
    mesa
  ];

  steamInspiredLibraries = with pkgs; [
    # Inspired by Steam:
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/st/steam/package.nix
    coreutils
    glibc
    libdrm
    libgbm
    libxcrypt
    networkmanager
    pciutils
    udev
    vulkan-loader
    zenity
  ];

  linuxSecurityCompatibilityLibraries = lib.optionals pkgs.stdenv.isLinux (with pkgs; [
    acl
    libapparmor
    libseccomp
    libselinux
  ]);

  nonAarch64CompatibilityLibraries = lib.optionals (pkgs.stdenv.isLinux && !pkgs.stdenv.hostPlatform.isAarch64) (with pkgs; [
    # Useful for some x86 binaries; avoid on AArch64.
    glibc_multi.bin
  ]);

  fragileAppImageCompatibilityLibraries =
    (with pkgs; [
      # Some AppImages fail silently without these.
      SDL2
      cups
      dbus-glib
      ffmpeg
      gnome2.GConf
      libcap
      libice
      libsm
      libusb1
      libudev0-shim
      libxcursor
      libxi
      libxinerama
      libxrender
      libxscrnsaver
      nspr
      nss
    ])
    ++ linuxSecurityCompatibilityLibraries
    ++ nonAarch64CompatibilityLibraries;

  nixLdCompatibilityLibraries = lib.unique (
    graphicalCompatibilityLibraries
    ++ requiredRuntimeLibraries
    ++ steamInspiredLibraries
    ++ fragileAppImageCompatibilityLibraries
  );
in {
  config = {
    programs.nix-ld = {
      enable = true;
      libraries = nixLdCompatibilityLibraries;
    };

    programs.appimage = {
      enable = true;
      binfmt = true;
    };
  };
}
