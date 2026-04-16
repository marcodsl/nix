{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatStringsSep isAttrs flip pipe mapAttrsRecursive collect listToAttrs;

  flattenAttrs' = let
    expandAttr = path: value: {
      inherit value;
      name = concatStringsSep "." path;
      __expanded__ = true;
    };
    isExpanded = v: isAttrs v -> v ? "__expanded__";
  in
    flip pipe [(mapAttrsRecursive expandAttr) (collect isExpanded) listToAttrs];
in {
  config = {
    boot = {
      tmp = {
        cleanOnBoot = true;
        useTmpfs = true;
        tmpfsSize = "25%";
      };

      kernelParams = [
        "splash"
      ];

      kernel.sysctl = flattenAttrs' {
        fs.inotify.max_user_watches = 524288;

        vm = {
          vfs_cache_pressure = 50;
          dirty_ratio = 10;
        };
      };

      blacklistedKernelModules = [
        # Additional entries not covered by nix-mineral's Kicksecure blacklist
        "r8188eu"

        # Old or rare or insufficiently audited filesystems
        "adfs"
        "affs"
        "bfs"
        "befs"
        "efs"
        "erofs"
        "exofs"
        "f2fs"
        "hpfs"
        "minix"
        "nilfs2"
        "ntfs"
        "omfs"
        "qnx4"
        "qnx6"
        "sysv"
        "ufs"
      ];
    };

    hardware = {
      firmware = with pkgs; [linux-firmware];

      amdgpu.initrd.enable = true;
    };
  };
}
