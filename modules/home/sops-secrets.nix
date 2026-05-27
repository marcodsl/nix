# SPDX-License-Identifier: Apache-2.0
{
  flake,
  config,
  ...
}: {
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = flake.inputs.self + /secrets/hosts/armadillo.yaml;

    secrets = {
      "mcp/github-token" = {};
      "mcp/linear-token" = {};
      "mcp/todoist-token" = {};
      "mcp/betterstack-token" = {};

      "betterstack/claude_source_token" = {};
      "betterstack/claude_otel_endpoint" = {};

      "pushover/api_token" = {};
      "pushover/user_key" = {};

      "senpai/password" = {};
    };

    templates."claude-otel.env" = {
      content = let
        ep = config.sops.placeholder."betterstack/claude_otel_endpoint";
      in ''
        OTEL_EXPORTER_OTLP_ENDPOINT=${ep}
        OTEL_EXPORTER_OTLP_METRICS_ENDPOINT=${ep}/v1/metrics
        OTEL_EXPORTER_OTLP_LOGS_ENDPOINT=${ep}/v1/logs
        OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=${ep}/v1/traces
      '';
    };
  };
}
