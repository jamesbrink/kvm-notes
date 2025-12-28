# QEMU guest configuration
# Enables virtio drivers and QEMU guest agent for optimal VM performance
#
# This is the NixOS equivalent of the QEMU/KVM optimizations in AlmaLinux
{ config, lib, pkgs, modulesPath, ... }:

{
  # Import the standard NixOS QEMU guest profile
  # This includes sensible defaults for running under QEMU/KVM
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  # QEMU guest agent for host communication
  # Enables:
  # - Guest shutdown/reboot from host
  # - Filesystem freeze for snapshots
  # - Memory ballooning
  services.qemuGuest.enable = true;

  # Ensure virtio modules are available in initrd
  # These are already included by qemu-guest.nix but explicitly listing
  # for educational purposes
  boot.initrd.availableKernelModules = [
    "virtio_pci"     # PCI virtio transport
    "virtio_blk"     # Block device (disk)
    "virtio_scsi"    # SCSI controller
    "virtio_net"     # Network device
    "virtio_balloon" # Memory ballooning
  ];

  # Use virtio-based random number generator if available
  boot.initrd.kernelModules = [ "virtio_rng" ];
}
