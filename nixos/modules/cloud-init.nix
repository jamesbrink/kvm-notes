# Cloud-init configuration for VM images
# Disabled by default for fast local boot.
# Enable for cloud deployments (EC2, OpenStack, etc.)
#
# To enable: set services.cloud-init.enable = true in your config
{ config, lib, pkgs, ... }:

{
  # Cloud-init disabled by default for fast local QEMU boot
  # Enable this for cloud deployments where you need:
  # - SSH key injection
  # - Hostname setting from metadata
  # - User creation from userdata
  # - Network configuration from cloud platform
  services.cloud-init.enable = lib.mkDefault false;

  # Grow partition to fill available disk space
  # Works without cloud-init via systemd-growfs
  boot.growPartition = true;

  # Cloud utilities (growpart, etc.) - useful even without cloud-init
  environment.systemPackages = with pkgs; [
    cloud-utils
  ];
}
