{lib, ...}: let
  flags = ''
    --ozone-platform=wayland
    --enable-features=VaapiVideoDecoder,VaapiVideoEncoder
  '';
in {
  home.file = lib.genAttrs [
    ".config/brave-flags.conf"
    ".config/chrome-flags.conf"
    ".config/chromium-flags.conf"
    ".config/electron-flags.conf"
  ] (_: {text = flags;});
}
