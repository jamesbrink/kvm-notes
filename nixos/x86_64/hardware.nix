# x86_64 hardware configuration
# Bootloader and filesystem settings specific to x86_64 VMs
#
# Uses GRUB with hybrid MBR/GPT for maximum compatibility
{ config, lib, pkgs, ... }:

{
  # GRUB bootloader for x86_64
  # Uses hybrid partition table so it works with both BIOS and UEFI
  boot.loader.grub = {
    enable = true;

    # Target device for GRUB installation
    # /dev/vda is the virtio disk device
    device = lib.mkDefault "/dev/vda";

    # Enable EFI support for UEFI-based VMs
    efiSupport = true;

    # Install as removable so it works without NVRAM
    # Important for VM images that may boot on different hosts
    efiInstallAsRemovable = true;
  };

  # Don't try to modify EFI variables (we're a VM image)
  boot.loader.efi.canTouchEfiVariables = false;

  # Root filesystem
  # Uses disk label for portability (works regardless of device name)
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  # No swap by default (can be added via cloud-init if needed)
  swapDevices = [ ];
}
