{
  config,
  lib,
  ...
}: let
  cfg = config.marco.services.ollama;
in {
  options.marco.services.ollama.enable = lib.mkEnableOption "Ollama service";

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      openFirewall = lib.mkDefault false;

      syncModels = true;
      loadModels = [
        "deepseek-r1:8b"
        "gemma4:e4b"
        "llama3.1:8b"
        "qwen3.5:9b"
      ];
    };

    systemd.services.ollama.serviceConfig.EnvironmentFile = config.sops.templates."ollama.env".path;
  };
}
