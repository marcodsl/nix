# SPDX-License-Identifier: Apache-2.0
{lib, ...}: {
  flake.lib = lib.makeExtensible (_final: {
    mkSettingsMerge = pkgs:
      import ./settings-merge.nix {inherit lib pkgs;};
  });
}
