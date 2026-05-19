# SPDX-License-Identifier: Apache-2.0
{
  lib,
  pkgs,
}: {
  name,
  format,
  deep,
}: let
  formats = {
    json = {
      imports = "import json";
      loadExpr = "json.loads(text)";
      dumpExpr = "json.dumps(data, indent=2, sort_keys=True)";
      libraries = [];
    };
    toml = {
      imports = "import tomllib\nimport tomli_w";
      loadExpr = "tomllib.loads(text)";
      dumpExpr = "tomli_w.dumps(data)";
      libraries = [pkgs.python3Packages.tomli-w];
    };
  };
  selectedFormat =
    formats.${format}
    or (throw "unsupported settings merge format: ${format}");
  deepLiteral =
    if deep
    then "True"
    else "False";
in
  pkgs.writers.writePython3Bin name {
    libraries = selectedFormat.libraries;
    flakeIgnore = ["E501" "W503"];
  } ''
    import argparse
    import copy
    import os
    ${selectedFormat.imports}
    from pathlib import Path

    DEEP = ${deepLiteral}


    def load(p):
        try:
            text = p.read_text()
        except FileNotFoundError:
            return {}
        return ${selectedFormat.loadExpr} if text.strip() else {}


    def dump(p, data):
        p.parent.mkdir(parents=True, exist_ok=True)
        tmp = p.with_name(p.name + ".tmp")
        tmp.write_text(${selectedFormat.dumpExpr})
        os.replace(tmp, p)


    def merge_into(dst, src):
        for key, value in src.items():
            if DEEP and isinstance(value, dict) and isinstance(dst.get(key), dict):
                merge_into(dst[key], value)
            else:
                dst[key] = value


    def remove_dropped(prev, current, user):
        if not isinstance(user, dict):
            return
        for key, prev_value in prev.items():
            if key not in current:
                user.pop(key, None)
            elif (
                DEEP
                and isinstance(prev_value, dict)
                and isinstance(current[key], dict)
                and isinstance(user.get(key), dict)
            ):
                remove_dropped(prev_value, current[key], user[key])


    def main():
        parser = argparse.ArgumentParser()
        parser.add_argument("--state", action="append", required=True, type=Path,
                            help="Nix-managed state file; repeatable, later files override earlier.")
        parser.add_argument("--prev-state", required=True, type=Path,
                            help="Snapshot of the last composed state, for dropped-key detection.")
        parser.add_argument("--user", required=True, type=Path,
                            help="User-writable config file to reconcile.")
        args = parser.parse_args()

        composed = {}
        for s in args.state:
            merge_into(composed, load(s))

        prev = load(args.prev_state)
        user = load(args.user)
        original = copy.deepcopy(user)

        remove_dropped(prev, composed, user)
        merge_into(user, composed)

        if user != original:
            dump(args.user, user)
        if composed != prev:
            dump(args.prev_state, composed)


    if __name__ == "__main__":
        main()
  ''
