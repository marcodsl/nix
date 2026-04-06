{
  config,
  lib,
  pkgs,
  ...
}: let
  gnomeExtensions = with pkgs.gnomeExtensions; [
    appindicator
    arcmenu
    blur-my-shell
    dash-to-panel
  ];

  systemPackages =
    (with pkgs; [
      gnome-tweaks
      sysprof
    ])
    ++ gnomeExtensions;
in {
  config = lib.mkIf config.services.desktopManager.gnome.enable {
    services.dbus.packages = with pkgs; [gnome2.GConf];
    services.sysprof.enable = lib.mkDefault true;

    environment.systemPackages = systemPackages;

    programs.dconf = {
      enable = lib.mkDefault true;

      profiles.user.databases =
        lib.singleton
        {
          settings = {
            "org/gnome/shell" = {
              enabled-extensions =
                lib.map (ext: ext.extensionUuid) gnomeExtensions;
            };

            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
            };
          };
        };
    };

    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };
  };
}
