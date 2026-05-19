# SPDX-License-Identifier: Apache-2.0
{
  flake,
  config,
  lib,
  ...
}: {
  sops = {
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    defaultSopsFile = flake.inputs.self + /secrets/hosts/armadillo.yaml;

    secrets =
      {
        "ollama/api_key" = {};
        "github/token" = {};

        "betterstack/vector_source_token" = {};
        "betterstack/vector_ingesting_host" = {};

        "litellm/openai_api_key" = {};
        "litellm/openai_vector_store_id" = {};
        "litellm/master_key" = {};

        "networkmanager/wifi_profile" = {
          mode = "0400";
          restartUnits = ["networkmanager-static-wifi.service"];
        };

        "cloudflared/token" = {
          mode = "0400";
        };
      }
      // lib.optionalAttrs config.marco.services.falcon-sensor.enable {
        "falcon/cid" = {
          mode = "0400";
          restartUnits = ["falcon-register.service"];
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
          BETTERSTACK_SOURCE_TOKEN=${config.sops.placeholder."betterstack/vector_source_token"}
          BETTERSTACK_INGESTING_HOST=${config.sops.placeholder."betterstack/vector_ingesting_host"}
        '';
        mode = "0440";
      };

      "litellm.env" = {
        content = ''
          OPENAI_API_KEY=${config.sops.placeholder."litellm/openai_api_key"}
          OPENAI_VECTOR_STORE_ID=${config.sops.placeholder."litellm/openai_vector_store_id"}
          LITELLM_MASTER_KEY=${config.sops.placeholder."litellm/master_key"}
        '';
        mode = "0400";
      };
    };
  };
}
