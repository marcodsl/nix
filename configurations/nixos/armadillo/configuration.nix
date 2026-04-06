{
  config,
  lib,
  ...
}: {
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/43ac8b94-3ddd-4c57-8f51-e6fcb7acf113";
    fsType = "ext4";
    neededForBoot = true;
  };

  boot.initrd.luks.devices = {
    "luks-f7465fe9-f37a-4df2-bf23-def022d3a801".device = "/dev/disk/by-uuid/f7465fe9-f37a-4df2-bf23-def022d3a801";
    "luks-8c82790b-f0b1-4924-9bf2-a33144b6b1b5".device = "/dev/disk/by-uuid/8c82790b-f0b1-4924-9bf2-a33144b6b1b5";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1329-D55A";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [
    {device = "/dev/mapper/luks-8c82790b-f0b1-4924-9bf2-a33144b6b1b5";}
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "armadillo";

  nixpkgs.hostPlatform = "x86_64-linux";

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.xserver = {
    xkb = {
      layout = "br";
      variant = "abnt2";
    };
  };

  console.keyMap = "br-abnt2";

  system.stateVersion = "24.11";
}
