# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KVM/QEMU VM development tooling for building AlmaLinux 10 images using Packer. Uses Nix flakes for reproducible cross-platform development (macOS + Linux).

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

## Architecture

### Platform-Specific Acceleration
- **Linux**: KVM acceleration (`-machine q35,accel=kvm`)
- **macOS Intel**: HVF or software emulation
- **macOS Apple Silicon**: HVF for ARM64, Lima recommended due to VNC boot issues

### Key Directories
- `packer/almalinux10/x86_64/` - x86_64 packer config (Linux KVM)
- `packer/almalinux10/aarch64/` - ARM64 packer config (HVF/KVM)
- Each arch has `almalinux10.pkr.hcl` (Packer HCL2) and `http/ks.cfg` (kickstart)

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
- `QEMU_EFI_AARCH64` env var - Auto-set to UEFI firmware path on macOS
- `nixosModules.vm-host` - NixOS module for configuring libvirtd

## Output Locations

Built images go to `packer/almalinux10/output/` (gitignored):
- x86_64: `output/almalinux10/almalinux10`
- aarch64: `output/almalinux10-aarch64/almalinux10-aarch64`
