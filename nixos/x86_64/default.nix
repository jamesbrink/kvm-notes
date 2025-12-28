# x86_64 NixOS VM configuration
# Main configuration file for x86_64-linux VM images
#
# Build with: nix build .#nixos-x86_64-image
# Run with:   just run-nixos-x86
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware.nix
  ];

  # Serial console configuration for x86_64
  # ttyS0 is the standard serial port on x86
  # This matches AlmaLinux kickstart: console=ttyS0,115200n8
  boot.kernelParams = [
    "console=tty0"            # Primary console (VGA)
    "console=ttyS0,115200n8"  # Serial console for headless access
  ];

  # Enable serial console getty
  # Allows login via serial console (QEMU -nographic mode)
  systemd.services."serial-getty@ttyS0".enable = true;

  # Disk image build configuration
  # This creates the qcow2 image when you run `nix build`
  #
  # The make-disk-image.nix script:
  # 1. Creates a disk image with partitions
  # 2. Installs NixOS using the configuration
  # 3. Outputs a compressed qcow2 file
  #
  # IMPORTANT: This can only be built on x86_64-linux!
  # It uses runInLinuxVM which requires native execution.
  system.build.qcow2 = import "${modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;

    # Disk size in MB (20GB matches AlmaLinux builds)
    diskSize = 20 * 1024;

    # Output format: qcow2 for QEMU, supports snapshots and compression
    format = "qcow2";

    # Partition table type:
    # - "hybrid": MBR + GPT, works with both BIOS and UEFI
    # - "efi": GPT only, UEFI only
    # - "legacy": MBR only, BIOS only
    partitionTableType = "hybrid";

    # Additional disk image options
    additionalSpace = "0M";  # No extra space (growPartition handles this)
  };
}
