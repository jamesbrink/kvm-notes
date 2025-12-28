# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KVM/QEMU VM development tooling for building VM images. Supports:
- **AlmaLinux 10** via Packer with kickstart
- **NixOS** via native Nix `make-disk-image.nix`

Uses Nix flakes for reproducible cross-platform development (macOS + Linux).

## Common Commands

```shell
# Enter dev environment
nix develop

# See all available commands
just

# Format HCL files
just fmt

# Validate packer configs
just lint
```

### Building VMs

**On Linux (with KVM):**
```shell
just build-alma-x86      # Build x86_64 image
just run-alma-x86        # Run the built image
just ssh-alma            # SSH into running VM (port 2222)
```

**On macOS Apple Silicon:**
```shell
# RECOMMENDED: Use Lima for reliable ARM VMs
just lima-start          # Start AlmaLinux 10 VM
just lima-shell          # Shell into Lima VM

# Alternative: Packer build (VNC boot commands unreliable on HVF)
just build-alma-arm      # Build ARM64 image
just run-alma-arm        # Run the built image
```

**Remote builds (sync to Linux host):**
```shell
just remote-sync-build hal9000   # Sync and build on remote
just remote-fetch-x86 hal9000    # Fetch built image
```

### NixOS VM Images

NixOS VMs are built using Nix's native `make-disk-image.nix`. **Important:** Disk images cannot cross-compile - must build on native architecture.

**On Linux (native builds):**
```shell
just build-nixos-x86     # Build x86_64 image (on x86_64-linux)
just build-nixos-arm     # Build aarch64 image (on aarch64-linux)
just run-nixos-x86       # Run x86_64 image (KVM)
just ssh-nixos           # SSH into running NixOS VM (port 2223)
```

**On macOS (remote builds):**
```shell
just remote-build-nixos-x86 hal9000   # Build on remote Linux host
just remote-fetch-nixos-x86 hal9000   # Fetch built image
just run-nixos-arm                    # Run aarch64 image with HVF
```

## Architecture

### Platform-Specific Acceleration
- **Linux**: KVM acceleration (`-machine q35,accel=kvm`)
- **macOS Intel**: HVF or software emulation
- **macOS Apple Silicon**: HVF for ARM64, Lima recommended due to VNC boot issues

### Key Directories
- `packer/almalinux10/x86_64/` - x86_64 packer config (Linux KVM)
- `packer/almalinux10/aarch64/` - ARM64 packer config (HVF/KVM)
- `nixos/x86_64/` - x86_64 NixOS configuration
- `nixos/aarch64/` - aarch64 NixOS configuration
- `nixos/modules/` - Shared NixOS modules (base, cloud-init, qemu-guest)

### Kickstart Files
The `http/ks.cfg` files use `cmdline` mode for fully automated installs. Key settings:
- Root password: `packer` (plaintext for dev builds)
- Admin user: `admin` / `admin` with passwordless sudo
- Serial console enabled: `ttyS0` (x86_64) or `ttyAMA0` (aarch64)

### aarch64/HVF Limitation
VNC boot commands don't reliably reach GRUB on macOS QEMU/HVF. The aarch64 template uses OEMDRV CD for kickstart delivery with manual VNC intervention or Lima as alternative.

## Default VM Credentials

| User | Password | Notes |
|------|----------|-------|
| root | packer | SSH enabled |
| admin | admin | Passwordless sudo |

VNC password: `password`

## Nix Flake Structure

The flake provides:
- `devShells.default` - Platform-specific tools (QEMU, Lima on macOS; libvirt on Linux)
- `nixosConfigurations.nixos-x86_64` - NixOS x86_64 VM configuration
- `nixosConfigurations.nixos-aarch64` - NixOS aarch64 VM configuration
- `packages.x86_64-linux.nixos-x86_64-image` - Build qcow2 image (x86_64)
- `packages.aarch64-linux.nixos-aarch64-image` - Build qcow2 image (aarch64)
- `nixosModules.vm-host` - NixOS module for configuring libvirtd
- `QEMU_EFI_AARCH64` env var - Auto-set to UEFI firmware path on macOS

## Output Locations

**AlmaLinux (Packer)** - `packer/almalinux10/output/` (gitignored):
- x86_64: `output/almalinux10/almalinux10`
- aarch64: `output/almalinux10-aarch64/almalinux10-aarch64`

**NixOS** - `nixos/output/` (gitignored):
- x86_64: `nixos/output/nixos-x86_64/nixos.qcow2`
- aarch64: `nixos/output/nixos-aarch64/nixos.qcow2`
