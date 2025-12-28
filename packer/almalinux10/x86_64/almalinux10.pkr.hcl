# AlmaLinux 10 Packer Template
# Modern HCL2 format for building KVM/QEMU images

packer {
  required_version = ">= 1.9.0"

  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

# Variables
variable "vm_name" {
  type        = string
  default     = "almalinux10"
  description = "Name of the VM and output image"
}

variable "iso_url" {
  type        = string
  default     = "https://repo.almalinux.org/almalinux/10.1/isos/x86_64/AlmaLinux-10.1-x86_64-boot.iso"
  description = "URL to the AlmaLinux boot ISO"
}

variable "iso_checksum" {
  type        = string
  default     = "sha256:68a9e14fa252c817d11a3c80306e5a21b2db37c21173fd3f52a9eb6ced25a4a0"
  description = "SHA256 checksum of the ISO"
}

variable "disk_size" {
  type        = string
  default     = "20G"
  description = "Size of the virtual disk"
}

variable "memory" {
  type        = number
  default     = 2048
  description = "RAM in MB"
}

variable "cpus" {
  type        = number
  default     = 2
  description = "Number of CPUs"
}

variable "ssh_username" {
  type        = string
  default     = "root"
  description = "SSH username for provisioning"
}

variable "ssh_password" {
  type        = string
  default     = "packer"
  sensitive   = true
  description = "SSH password for provisioning"
}

variable "headless" {
  type        = bool
  default     = true
  description = "Run in headless mode (no GUI)"
}

variable "accelerator" {
  type        = string
  default     = "kvm"
  description = "QEMU accelerator (kvm, hvf, tcg)"
}

variable "cpu_type" {
  type        = string
  default     = "host"
  description = "CPU type (host for KVM/HVF, qemu64 for TCG)"
}

# Local variables
locals {
  output_directory = "${path.root}/../output/${var.vm_name}"
  http_directory   = "${path.root}/http"
}

# QEMU Builder
source "qemu" "almalinux10" {
  vm_name          = var.vm_name
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  output_directory = local.output_directory

  # Hardware configuration
  memory      = var.memory
  cpus        = var.cpus
  disk_size   = var.disk_size
  accelerator = var.accelerator

  # Disk configuration
  format           = "qcow2"
  disk_interface   = "virtio"
  disk_compression = true

  # Network configuration
  net_device = "virtio-net"

  # Boot configuration - kickstart via HTTP
  http_directory = local.http_directory
  boot_wait      = "5s"
  boot_command = [
    "<up><wait>",
    "e<wait>",
    "<down><down><end>",
    " inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg",
    "<leftCtrlOn>x<leftCtrlOff>"
  ]

  # SSH configuration for provisioning
  ssh_username     = var.ssh_username
  ssh_password     = var.ssh_password
  ssh_timeout      = "30m"
  shutdown_command = "shutdown -P now"

  # Display
  headless         = var.headless
  vnc_bind_address = "0.0.0.0"
  vnc_password     = "password"

  # QEMU-specific settings
  qemuargs = [
    ["-cpu", "${var.cpu_type}"],
    ["-machine", "q35,accel=${var.accelerator}"],
  ]
}

# Build definition
build {
  name    = "almalinux10"
  sources = ["source.qemu.almalinux10"]

  # Basic provisioner - install cloud-init for future flexibility
  provisioner "shell" {
    inline = [
      "dnf -y update",
      "dnf -y install cloud-init cloud-utils-growpart",
      "systemctl enable cloud-init",
      "dnf clean all",
      # Clean up for smaller image
      "rm -rf /var/cache/dnf/*",
      "rm -f /etc/machine-id",
      "truncate -s 0 /etc/machine-id",
      # Zero out free space for better compression
      "dd if=/dev/zero of=/EMPTY bs=1M || true",
      "rm -f /EMPTY",
      "sync"
    ]
  }

  # Output manifest
  post-processor "manifest" {
    output     = "${local.output_directory}/manifest.json"
    strip_path = true
  }
}
