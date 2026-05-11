# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  ...
}: let
  cfg = config.marco.services.vector;
in {
  options.marco.services.vector.enable =
    lib.mkEnableOption "BetterStack Vector log and host-metric shipping";

  config = lib.mkIf cfg.enable {
    services.vector = {
      enable = true;
      journaldAccess = true;

      # Disabled because URI and token use ${ENV} interpolation that is only
      # resolved at runtime from EnvironmentFile; `vector validate` would fail.
      validateConfig = false;

      settings = {
        sources = {
          journald = {
            type = "journald";
            current_boot_only = true;
          };

          host_metrics = {
            type = "host_metrics";
            scrape_interval_secs = 120;
            collectors = ["cpu" "disk" "filesystem" "host" "load" "memory" "network"];
            filesystem.mountpoints.excludes = ["/run/user/*/*"];
          };
        };

        transforms = {
          enrich_journald = {
            type = "remap";
            inputs = ["journald"];
            source = ''
              prio = to_int(.PRIORITY) ?? 6
              .level = if prio <= 3 {
                "error"
              } else if prio == 4 {
                "warn"
              } else if prio == 5 {
                "notice"
              } else if prio == 6 {
                "info"
              } else {
                "debug"
              }

              msg = string!(.message)
              if starts_with(msg, "{") {
                parsed, err = parse_json(msg)
                if err == null && is_object(parsed) {
                  .json = parsed
                  json_level = .json.level
                  if json_level == null { json_level = .json.severity }
                  if json_level == null { json_level = .json.lvl }
                  if json_level != null {
                    .level = downcase(to_string!(json_level))
                  }
                }
              }

              if exists(._SYSTEMD_UNIT) {
                .unit = del(._SYSTEMD_UNIT)
              }

              del(.PRIORITY)
              del(._CMDLINE)
              del(._BOOT_ID)
              del(._MACHINE_ID)
              del(._SYSTEMD_INVOCATION_ID)
              del(._SYSTEMD_OWNER_UID)
              del(._SYSTEMD_SLICE)
              del(._SYSTEMD_CGROUP)
              del(._SYSTEMD_USER_SLICE)
              del(._SYSTEMD_USER_UNIT)
              del(._CAP_EFFECTIVE)
              del(._GID)
              del(._UID)
              del(._SELINUX_CONTEXT)
              del(._TRANSPORT)
              del(._SOURCE_REALTIME_TIMESTAMP)
              del(.SYSLOG_FACILITY)
            '';
          };

          # Drop known unit/message patterns that dominate journal volume
          # without operational value.
          filter_noise = {
            type = "filter";
            inputs = ["enrich_journald"];
            condition = ''
              unit = to_string(.unit) ?? ""
              msg = to_string(.message) ?? ""
              level = to_string(.level) ?? ""

              is_webview_preload = unit == "user@1000.service" && contains(msg, "preloaded using link preload but not used")
              is_osk_warn = unit == "user@1000.service" && contains(msg, "failed to activate the on-screen keyboard")
              is_tailscale_chatter = unit == "tailscaled.service" && level == "info" && (starts_with(msg, "magicsock: ") || starts_with(msg, "derphttp.Client.Recv"))

              !(is_webview_preload || is_osk_warn || is_tailscale_chatter)
            '';
          };

          log_metrics = {
            type = "log_to_metric";
            inputs = ["filter_noise"];
            metrics = [
              {
                type = "counter";
                field = "level";
                name = "log_events_total";
                tags = {
                  unit = "{{unit}}";
                  level = "{{level}}";
                };
              }
            ];
          };
        };

        sinks = {
          betterstack_logs = {
            type = "http";
            inputs = ["filter_noise"];
            method = "post";
            uri = "https://\${BETTERSTACK_INGESTING_HOST}/";
            encoding.codec = "json";
            framing.method = "newline_delimited";
            compression = "gzip";
            auth = {
              strategy = "bearer";
              token = "\${BETTERSTACK_SOURCE_TOKEN}";
            };
          };

          betterstack_metrics = {
            type = "prometheus_remote_write";
            inputs = ["host_metrics" "log_metrics"];
            endpoint = "https://\${BETTERSTACK_INGESTING_HOST}/metrics";
            auth = {
              strategy = "bearer";
              token = "\${BETTERSTACK_SOURCE_TOKEN}";
            };
          };
        };
      };
    };

    systemd.services.vector.serviceConfig.EnvironmentFile =
      config.sops.templates."vector.env".path;
  };
}
