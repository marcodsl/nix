{
  config,
  lib,
  pkgs,
  ...
}: let
  amo = slug: "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
  pin = slug: {
    install_url = amo slug;
    installation_mode = "force_installed";
    updates_disabled = false;
  };
  prefDefault = v: {
    Value = v;
    Status = "default";
  };

  uBlockImportedLists = [
    "https://filters.adtidy.org/extension/ublock/filters/3.txt"
    "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
  ];
in {
  programs.firefox = {
    enable = true;

    configPath = "${config.xdg.configHome}/mozilla/firefox";

    languagePacks = ["en-US"];

    policies = {
      # Updates & Background Services
      AppAutoUpdate = false;
      BackgroundAppUpdate = false;

      # Feature Disabling
      DisableBuiltinPDFViewer = true;
      DisableFirefoxStudies = true;
      DisableFirefoxAccounts = true;
      DisableFirefoxScreenshots = true;
      DisableForgetButton = true;
      DisableMasterPasswordCreation = true;
      DisableProfileImport = true;
      DisableProfileRefresh = true;
      DisableSetDesktopBackground = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DisableFormHistory = true;
      DisablePasswordReveal = true;

      # Access Restrictions
      BlockAboutConfig = false;
      BlockAboutProfiles = true;
      BlockAboutSupport = true;

      # UI and Behavior
      DisplayMenuBar = "never";
      DontCheckDefaultBrowser = true;
      HardwareAcceleration = true;
      OfferToSaveLogins = false;
      DefaultDownloadDirectory = "${config.home.homeDirectory}/Downloads";
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";

      # Privacy & Security
      HTTPSOnlyMode = "force_enabled";

      DNSOverHTTPS = {
        Enabled = true;
        ProviderURL = "https://mozilla.cloudflare-dns.com/dns-query";
        Locked = false;
      };

      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
      };

      Cookies = {
        Behavior = "reject-tracker-and-partition-foreign";
        BehaviorPrivateBrowsing = "reject-tracker-and-partition-foreign";
      };

      UserMessaging = {
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        UrlbarInterventions = false;
        MoreFromMozilla = false;
        SkipOnboarding = true;
      };

      FirefoxHome = {
        Search = true;
        TopSites = true;
        SponsoredTopSites = false;
        Highlights = false;
        Pocket = false;
        SponsoredPocket = false;
        Snippets = false;
      };

      Preferences = {
        "privacy.globalprivacycontrol.enabled" = prefDefault true;
        "privacy.donottrackheader.enabled" = prefDefault true;
        "beacon.enabled" = prefDefault false;
        "network.prefetch-next" = prefDefault false;
        "network.dns.disablePrefetch" = prefDefault true;
        "network.predictor.enabled" = prefDefault false;
        "media.peerconnection.ice.default_address_only" = prefDefault true;
        "extensions.formautofill.creditCards.enabled" = prefDefault false;
        "browser.urlbar.suggest.topsites" = prefDefault false;
        "pdfjs.enableScripting" = prefDefault false;
      };

      # Extensions
      ExtensionSettings = {
        "*".installation_mode = "blocked";
        "uBlock0@raymondhill.net" = pin "ublock-origin";
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = pin "bitwarden-password-manager";
        "{81b74d53-9416-4fb3-afa2-ab46684b253b}" = pin "tabwrangler";
        "support@todoist.com" = pin "todoist";
        "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" = pin "violentmonkey";
        "@testpilot-containers" = pin "multi-account-containers";
        "{ae166280-3fad-45c4-ae95-7a9c8f8c4c60}" = pin "atom-one-dark-theme";
      };

      # Extension configuration
      "3rdparty".Extensions = {
        "uBlock0@raymondhill.net".adminSettings = {
          userSettings = {
            uiTheme = "dark";
            uiAccentCustom = true;
            uiAccentCustom0 = "#8300ff";
            cloudStorageEnabled = false;
            importedLists = uBlockImportedLists;
            externalLists = lib.concatStringsSep "\n" uBlockImportedLists;
          };

          selectedFilterLists = [
            "CZE-0"
            "adguard-generic"
            "adguard-annoyance"
            "adguard-social"
            "adguard-spyware-url"
            "easylist"
            "easyprivacy"
            "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
            "plowe-0"
            "ublock-abuse"
            "ublock-badware"
            "ublock-filters"
            "ublock-privacy"
            "ublock-quick-fixes"
            "ublock-unbreak"
            "urlhaus-1"
          ];
        };
      };
    };

    profiles.default = {
      bookmarks = {
        force = true;
        settings = [
          {
            name = "Toolbar";
            toolbar = true;
            bookmarks = [
              {
                name = "Claude";
                url = "https://claude.ai";
              }
              {
                name = "Todoist";
                url = "https://todoist.com/app";
              }
              {
                name = "Bitwarden vault";
                url = "https://vault.bitwarden.com";
              }
            ];
          }
        ];
      };

      search = {
        force = true;
        default = "google";
        privateDefault = "google";

        engines = {
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@np"];
          };

          "Nix Options" = {
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@no"];
          };

          "NixOS Wiki" = {
            urls = [
              {
                template = "https://wiki.nixos.org/w/index.php";
                params = [
                  {
                    name = "search";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@nw"];
          };
        };
      };
    };
  };
}
