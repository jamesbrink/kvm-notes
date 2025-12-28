# aarch64 NixOS VM configuration
# Main configuration file for aarch64-linux VM images
#
# Build with: nix build .#nixos-aarch64-image
# Run with:   just run-nixos-arm
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware.nix
  ];

  # Serial console configuration for aarch64
  # ttyAMA0 is the ARM AMBA PL011 UART (standard on ARM virt machines)
  # This matches AlmaLinux kickstart: console=ttyAMA0,115200n8
  boot.kernelParams = [
    "console=tty0"              # Primary console (VGA if available)
    "console=ttyAMA0,115200n8"  # Serial console for headless access
  ];

  # Enable serial console getty
  # Allows login via serial console (QEMU -nographic mode)
  systemd.services."serial-getty@ttyAMA0".enable = true;

  # Disk image build configuration
  # This creates the qcow2 image when you run `nix build`
  #
  # IMPORTANT: This can only be built on aarch64-linux!
  # It uses runInLinuxVM which requires native execution.
  # On macOS, use remote build to an ARM Linux host.
  system.build.qcow2 = import "${modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;

    # Disk size in MB (20GB matches AlmaLinux builds)
    diskSize = 20 * 1024;

    # Output format: qcow2 for QEMU
    format = "qcow2";

    # Partition table type:
    # aarch64 requires UEFI, so we use "efi" (GPT with ESP)
    # This differs from x86_64 which uses "hybrid"
    partitionTableType = "efi";

    # Additional disk image options
    additionalSpace = "0M";
  };
}
