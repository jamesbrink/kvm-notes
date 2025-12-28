# aarch64 hardware configuration
# Bootloader and filesystem settings specific to ARM64 VMs
#
# Uses systemd-boot with UEFI (required for aarch64)
{ config, lib, pkgs, ... }:

{
  # systemd-boot for aarch64 UEFI
  # aarch64 requires UEFI boot (no legacy BIOS support)
  boot.loader.systemd-boot = {
    enable = true;

    # Use full editor (allows kernel params editing at boot)
    editor = true;
  };

  # Don't try to modify EFI variables (we're a VM image)
  boot.loader.efi.canTouchEfiVariables = false;

  # Root filesystem
  # Uses disk label for portability
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  # EFI System Partition
  # Required for UEFI boot on aarch64
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  # No swap by default
  swapDevices = [ ];
}
