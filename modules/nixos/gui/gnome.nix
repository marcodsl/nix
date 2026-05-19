{
  config,
  lib,
  pkgs,
  ...
}: let
  gnomeExtensions = with pkgs.gnomeExtensions; [
    appindicator
    arcmenu
    dash-to-panel
  ];

  systemPackages =
    (with pkgs; [
      gnome-tweaks
      sysprof
    ])
    ++ gnomeExtensions;

  lockedDconfSettings = {
    "org/gnome/desktop/session" = {
      idle-delay = lib.gvariant.mkUint32 0;
    };

    "org/gnome/desktop/screensaver" = {
      lock-enabled = false;
      idle-activation-enabled = false;
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "nothing";
    };
  };

  lockedDconfPaths = lib.flatten (lib.mapAttrsToList
    (path: settings: map (key: "/${path}/${key}") (lib.attrNames settings))
    lockedDconfSettings);
in {
  config = lib.mkIf config.services.desktopManager.gnome.enable {
    services.dbus.packages = with pkgs; [gnome2.GConf];
    services.sysprof.enable = false;

    services.gnome = {
      evolution-data-server.enable = lib.mkForce false;
      gnome-online-accounts.enable = lib.mkForce false;
    };

    environment.gnome.excludePackages = with pkgs; [
      epiphany
      evolution
      geary
      gnome-contacts
      gnome-maps
      gnome-music
      gnome-tour
      simple-scan
      yelp
    ];

    environment.systemPackages = systemPackages;

    systemd.user.services."org.gnome.Shell@wayland" = {
      overrideStrategy = "asDropin";
      serviceConfig.OOMScoreAdjust = -500;
    };

    programs.dconf = {
      enable = lib.mkDefault true;

      profiles.user.databases =
        lib.singleton
        {
          settings =
            {
              "org/gnome/shell" = {
                enabled-extensions =
                  lib.map (ext: ext.extensionUuid) gnomeExtensions;
              };

              "org/gnome/desktop/interface" = {
                color-scheme = "prefer-dark";
              };
            }
            // lockedDconfSettings;

          locks = lockedDconfPaths;
        };
    };

    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };
  };
}
