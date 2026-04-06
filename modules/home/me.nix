# User configuration module
{
  config,
  lib,
  ...
}: {
  options = {
    me = {
      username = lib.mkOption {
        type = lib.types.str;
        description = "Your username as shown by `id -un`";
      };
      fullname = lib.mkOption {
        type = lib.types.str;
        description = "Your full name for use in Git config";
      };
      email = lib.mkOption {
        type = lib.types.str;
        description = "Your email for use in Git config";
      };

      github.username = lib.mkOption {
        type = lib.types.str;
        description = "Your GitHub username for CLI host configuration";
      };

      terminal.font = {
        family = lib.mkOption {
          type = lib.types.str;
          description = "Shared terminal font family";
          default = "GeistMono Nerd Font";
        };

        size = lib.mkOption {
          type = lib.types.int;
          description = "Shared terminal font size";
          default = 11;
        };
      };
    };
  };

  config.home.username = config.me.username;
}
