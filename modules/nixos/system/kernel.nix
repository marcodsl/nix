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
        tmpfsSize = "50%";
      };

      kernelParams = [
        # Reduce TTY output on boot
        "quiet"
        "splash"
        "threadirqs"
      ];

      kernel.sysctl = flattenAttrs' {
        kernel = {
          nmi_watchdog = 0;
          split_lock_mitigate = 0;
          sched_autogroup_enabled = 1;
        };
        fs.inotify.max_user_watches = 524288;
        net = {
          core = {
            default_qdisc = "cake";
            netdev_max_backlog = 16384;
          };
          ipv4 = {
            tcp_congestion_control = "bbr2";
            tcp_fastopen = 3;
            tcp_timestamps = 0;
          };
        };
        vm = {
          vfs_cache_pressure = 50;
          swappiness = 10;
          dirty_ratio = 10;
        };
      };

      blacklistedKernelModules = [
        # Bad Realtek driver
        "r8188eu"

        # obscure network protocols
        "ax25"
        "netrom"
        "rose"

        # Old or rare or insufficiently audited filesystems
        "adfs"
        "affs"
        "bfs"
        "befs"
        "cramfs"
        "efs"
        "erofs"
        "exofs"
        "freevxfs"
        "f2f2"
        "hfs"
        "hpfs"
        "jfs"
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

    services = {
      lact.enable = true;

      scx = {
        enable = true;
        scheduler = "scx_bpfland";
      };
    };

    hardware = {
      firmware = with pkgs; [linux-firmware];

      amdgpu = {
        initrd.enable = true;
        overdrive.enable = true;
        opencl.enable = true;
      };
    };

    systemd.tmpfiles.rules = [
      "L+ /opt/rocm - - - - ${pkgs.rocmPackages.clr}"
    ];

    environment.systemPackages = with pkgs; [
      clinfo
      rocmPackages.clr
      rocmPackages.rocblas
      rocmPackages.hipblas
    ];
  };
}
