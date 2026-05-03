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
        "senpai/password" = {};
      };
    };
  };
}
