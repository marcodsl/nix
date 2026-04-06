{
  config,
  lib,
  ...
}: let
  cfg = config.marco.services.ollama;
in {
  options.marco.services.ollama.enable = lib.mkEnableOption "Ollama service";

  config = lib.mkIf cfg.enable {
    sops.secrets."ollama/api_key" = {};

    sops.templates."ollama.env" = {
      content = ''
        OLLAMA_API_KEY=${config.sops.placeholder."ollama/api_key"}
      '';
      mode = "0440";
    };

    services.ollama = {
      enable = true;
      # Phase 4 S-04: keep Ollama closed by default and opt in per host only when needed.
      openFirewall = lib.mkDefault false;

      environmentVariables = {
        OLLAMA_CONTEXT_LENGTH = "8192";
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "q4_0";
      };

      syncModels = true;
      loadModels = [
        # Local
        "deepseek-r1:8b"
        "dolphin3:8b"
        "gemma3:4b"
        "llama3.1:8b"
        "mistral:7b"
        "qwen3:8b"

        # Cloud
        "deepseek-v3.1:671b-cloud"
        "nemotron-3-super:cloud"
        "qwen3-coder:480b-cloud"
        "qwen3.5:cloud"
      ];
    };

    systemd.services.ollama.serviceConfig.EnvironmentFile = config.sops.templates."ollama.env".path;
  };
}
