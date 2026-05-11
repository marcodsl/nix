# SPDX-License-Identifier: Apache-2.0
{self}: let
  sopsFile = "${self}/secrets/hosts/armadillo.yaml";
in {
  nixos = {
    config,
    lib,
    ...
  }: {
    sops = {
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      defaultSopsFile = sopsFile;

      secrets = {
        "ollama/api_key" = {};
        "github/token" = {};

        "betterstack/source_token" = {};
        "betterstack/ingesting_host" = {};

        "networkmanager/wifi_profile" = {
          mode = "0400";
          restartUnits = ["networkmanager-static-wifi.service"];
        };
      };

      templates = {
        "nix/github-access-tokens.conf" = {
          path = "/etc/nix/github-access-tokens.conf";
          content = ''
            extra-access-tokens = github.com=${config.sops.placeholder."github/token"}
          '';
          owner = "root";
          group = config.users.users.marco.group;
          mode = "0440";
        };

        "ollama.env" = {
          content = ''
            OLLAMA_API_KEY=${config.sops.placeholder."ollama/api_key"}
          '';
          mode = "0440";
        };

        "vector.env" = {
          content = ''
            BETTERSTACK_SOURCE_TOKEN=${config.sops.placeholder."betterstack/source_token"}
            BETTERSTACK_INGESTING_HOST=${config.sops.placeholder."betterstack/ingesting_host"}
          '';
          mode = "0440";
        };
      };
    };
  };

  home = {config, ...}: {
    sops = {
      age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      defaultSopsFile = sopsFile;

      secrets = {
        "mcp/github-token" = {};
        "mcp/linear-token" = {};
        "mcp/todoist-token" = {};
        "senpai/password" = {};
      };
    };
  };
}
