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

| Platform | Acceleration | Use Case |
|----------|-------------|----------|
| Linux (hal9000) | KVM | Full VM building, production images |
| macOS | HVF / Lima | Development, testing |

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
├── flake.nix                    # Nix flake with devShells
├── justfile                     # Task runner commands
├── packer/
│   └── almalinux10/
│       ├── almalinux10.pkr.hcl  # Packer HCL2 template
│       └── http/
│           └── ks.cfg           # Kickstart file
├── legacy/                      # Legacy configs (CentOS 7, etc.)
└── README.md
```

## Available Commands

Run `just` to see all commands. Key ones:

```
Packer:
  just build-alma         # Build AlmaLinux 10 image
  just build-alma-debug   # Build with VNC console visible
  just packer-validate    # Validate packer config

QEMU (Linux):
  just run-alma           # Run image with serial console
  just run-alma-vnc       # Run with VNC display
  just ssh-alma           # SSH into running VM

Lima (macOS):
  just lima-start         # Start Lima VM
  just lima-shell         # Shell into Lima VM
  just lima-stop          # Stop Lima VM

Remote:
  just remote-sync-build  # Sync to hal9000 and build
  just remote-fetch       # Fetch built image from hal9000

Libvirt:
  just libvirt-import     # Import image into libvirt
  just libvirt-list       # List all VMs
  just libvirt-console    # Console into VM
```

## Configuration

### SSH Access

Default credentials (for packer builds):
- **root**: `packer`
- **admin**: `admin` (has passwordless sudo)

### VM Resources

Edit `packer/almalinux10/almalinux10.pkr.hcl`:
- `disk_size`: Default 20G
- `memory`: Default 2048 MB
- `cpus`: Default 2

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
