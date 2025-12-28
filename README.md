# KVM/QEMU VM Development

Quick reference and tools for spinning up VMs using KVM/QEMU. Uses Nix flakes for reproducible tooling across macOS and Linux.

## Quick Start

```shell
# Enter development environment
nix develop

# Or with direnv (automatic)
direnv allow

# See all available commands
just
```

## Platform Support

| Platform | Architecture | Acceleration | Recommended Approach |
|----------|-------------|-------------|---------------------|
| Linux (hal9000) | x86_64 | KVM | Packer builds - fully automated |
| Linux ARM | aarch64 | KVM | Packer builds - fully automated |
| macOS Intel | x86_64 | HVF | Lima or remote build on Linux |
| macOS Apple Silicon | aarch64 | HVF/VZ | **Lima** (recommended) or remote build |

> **Note**: Packer VNC boot commands have issues on macOS aarch64/HVF. Use Lima for local ARM VMs.

## Building AlmaLinux 10

### On Linux (with KVM)

```shell
# Build the image
just build-alma

# Run the built image
just run-alma

# SSH into the VM (port 2222)
just ssh-alma
```

### On macOS

For full KVM acceleration, build on a remote Linux host:

```shell
# Sync and build on hal9000
just remote-sync-build hal9000

# Fetch the built image
just remote-fetch hal9000
```

Or use Lima for quick local VMs:

```shell
# Start AlmaLinux via Lima
just lima-start

# Shell into the VM
just lima-shell
```

## Project Structure

```
├── flake.nix                           # Nix flake with devShells
├── justfile                            # Task runner commands
├── packer/
│   └── almalinux10/
│       ├── x86_64/                     # x86_64 builds (Linux KVM)
│       │   ├── almalinux10.pkr.hcl
│       │   └── http/ks.cfg
│       ├── aarch64/                    # ARM64 builds (Linux KVM or macOS HVF)
│       │   ├── almalinux10.pkr.hcl
│       │   └── http/ks.cfg
│       └── output/                     # Built images (gitignored)
├── legacy/                             # Legacy configs (CentOS 7, etc.)
└── README.md
```

## Available Commands

Run `just` to see all commands. Key ones:

```
Packer (x86_64 - Linux):
  just build-alma-x86     # Build x86_64 image (requires KVM)
  just run-alma-x86       # Run x86_64 image

Packer (aarch64 - Linux ARM or macOS):
  just build-alma-arm     # Build ARM64 image
  just run-alma-arm       # Run ARM64 image

Lima (macOS - RECOMMENDED for local VMs):
  just lima-start         # Start AlmaLinux 10 VM
  just lima-shell         # Shell into Lima VM
  just lima-stop          # Stop Lima VM
  just lima-templates     # List available templates

Remote Build:
  just remote-sync-build  # Sync to hal9000 and build x86_64
  just remote-fetch-x86   # Fetch built image from hal9000

Libvirt (Linux):
  just libvirt-import     # Import image into libvirt
  just libvirt-list       # List all VMs
  just libvirt-console    # Console into VM

Utilities:
  just fmt                # Format HCL files
  just lint               # Validate packer configs
  just ssh-alma           # SSH into running VM (port 2222)
```

## Configuration

### SSH Access

Default credentials (for packer builds):
- **root**: `packer`
- **admin**: `admin` (has passwordless sudo)

### VM Resources

Edit the packer template for your architecture:
- `packer/almalinux10/x86_64/almalinux10.pkr.hcl`
- `packer/almalinux10/aarch64/almalinux10.pkr.hcl`

Default settings:
- `disk_size`: 20G
- `memory`: 2048 MB
- `cpus`: 2

---

# Legacy Notes

The following are preserved from the original project for reference.

## virt-install Examples

### Debian 10

```shell
virt-install \
    --name debian10 \
    --ram 4096 \
    --disk path=./debian10.qcow2,size=20 \
    --vcpus 2 \
    --os-type linux \
    --os-variant debiantesting \
    --network default \
    --console pty,target_type=serial \
    --graphics vnc,listen=0.0.0.0 --noautoconsole \
    --location 'http://ftp.nl.debian.org/debian/dists/buster/main/installer-amd64/' \
    --extra-args 'console=ttyS0,115200n8 serial'
```

### Ubuntu 18.04

```shell
virt-install \
    --name ubuntu18.04 \
    --ram 8192 \
    --disk path=./ubuntu18.04.qcow2,size=40 \
    --vcpus 4 \
    --os-type linux \
    --os-variant ubuntu18.04 \
    --network default \
    --console pty,target_type=serial \
    --graphics vnc,listen=0.0.0.0 --noautoconsole \
    --location 'http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/' \
    --extra-args 'console=ttyS0,115200n8 serial'
```

### Alpine Linux

```shell
virt-install \
    --name alpine \
    --ram 512 \
    --disk path=./alpine.qcow2,size=2 \
    --vcpus 1 \
    --os-type linux \
    --os-variant alpinelinux3.8 \
    --network default \
    --console pty,target_type=serial \
    --graphics vnc,listen=0.0.0.0 --noautoconsole \
    --cdrom alpine-virt-3.10.1-x86_64.iso
```

### CentOS 7

```shell
virt-install \
    --name centos7 \
    --ram 4096 \
    --disk path=./centos7.qcow2,size=40 \
    --vcpus 2 \
    --os-type linux \
    --os-variant centos7.0 \
    --network default \
    --console pty,target_type=serial \
    --graphics none \
    --location 'https://mirrors.mit.edu/centos/7/os/x86_64/' \
    --extra-args 'console=ttyS0,115200n8 serial'
```

### Windows 10

```shell
virt-install \
    --name=windows10 \
    --ram=8192 \
    --cpu=host \
    --vcpus=2 \
    --os-type=windows \
    --os-variant=win8.1 \
    --network=default \
    --graphics spice,listen=0.0.0.0 \
    --disk windows10.qcow2,size=60 \
    --disk /usr/share/virtio/virtio-win.iso,device=cdrom \
    --cdrom windows10.iso
```

### MacOS 9.22 (QEMU PowerPC)

```shell
# Create disk
qemu-img create -f qcow2 MacOS-9.22.qcow2 512M

# Install from ISO
qemu-system-ppc -M mac99 -m 512M -hda MacOS-9.22.qcow2 -cdrom MacOS-9.22.iso -boot d

# Run installed system
qemu-system-ppc -M mac99 -m 512M -hda MacOS-9.22.qcow2
```

## Virsh Commands

### Snapshots

```shell
virsh snapshot-create-as --domain {VM-NAME} --name "{SNAPSHOT-NAME}"
```

### Reset Default Network

```shell
virsh net-destroy default
virsh net-undefine default
virsh net-define --file virsh-default-network.xml
virsh net-start default
virsh net-autostart default
```

## References

- [libvirt networking handbook](https://jamielinux.com/docs/libvirt-networking-handbook/)
- [virt-install examples](https://raymii.org/s/articles/virt-install_introduction_and_copy_paste_distro_install_commands.html)
- [AlmaLinux 10 Release Notes](https://wiki.almalinux.org/release-notes/10.1.html)
- [Packer QEMU Builder](https://developer.hashicorp.com/packer/integrations/hashicorp/qemu)
- [Lima VM](https://lima-vm.io/)
