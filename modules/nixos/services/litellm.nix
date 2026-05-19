# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  ...
}: let
  cfg = config.marco.services.litellm;

  env = name: "os.environ/${name}";

  openai = name: slug: {
    model_name = name;
    litellm_params = {
      model = "openai/${slug}";
      api_key = env "OPENAI_API_KEY";
    };
  };

  openai' = name: (openai name name);
in {
  options.marco.services.litellm.enable =
    lib.mkEnableOption "LiteLLM";

  config = lib.mkIf cfg.enable {
    services.litellm = {
      enable = true;
      host = "127.0.0.1";
      port = 18219;
      openFirewall = false;

      environmentFile = config.sops.templates."litellm.env".path;

      settings = {
        general_settings = {
          master_key = env "LITELLM_MASTER_KEY";
        };

        litellm_settings = {
          json_logs = true;
          drop_params = true;
          set_verbose = false;
        };

        model_list = [
          (openai' "gpt-5")
          (openai' "gpt-5-mini")
          (openai' "gpt-5-nano")
          (openai "embed-small" "text-embedding-3-small")
          (openai "embed-large" "text-embedding-3-large")
        ];

        vector_store_registry = [
          {
            vector_store_name = "openai";
            litellm_params = {
              api_key = env "OPENAI_API_KEY";
              custom_llm_provider = "openai";
              vector_store_id = env "OPENAI_VECTOR_STORE_ID";
            };
          }
        ];
      };
    };
  };
}
