# Cloud-init configuration for VM images
# Enables cloud-init for cloud deployments (EC2, OpenStack, etc.)
# and NoCloud datasource for local QEMU testing
#
# This matches the AlmaLinux builds which also include cloud-init
{ config, lib, pkgs, ... }:

{
  # Enable cloud-init service
  # Cloud-init handles:
  # - SSH key injection
  # - Hostname setting
  # - User creation
  # - Network configuration (on cloud platforms)
  services.cloud-init = {
    enable = true;

    # Enable network configuration via cloud-init
    # Useful for cloud platforms that provide network config via metadata
    network.enable = true;
  };

  # Grow partition to fill available disk space
  # Essential for cloud deployments where disk may be larger than image
  boot.growPartition = true;

  # Additional cloud-init packages
  environment.systemPackages = with pkgs; [
    cloud-utils   # growpart and other cloud utilities
  ];
}
