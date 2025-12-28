# KVM/QEMU VM Development

Quick reference and tools for spinning up VMs using KVM/QEMU. Supports building VM images via:
- **Packer** - AlmaLinux 10 with kickstart automation
- **NixOS** - Declarative NixOS VMs using `make-disk-image.nix`

Uses Nix flakes for reproducible tooling across macOS and Linux.

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

## Building NixOS VMs

NixOS images are built using Nix's native `make-disk-image.nix`. The configuration is fully declarative.

### Build Commands

```shell
# Build NixOS image (uses remote builder automatically from macOS)
nix build .#nixos-aarch64-image    # ARM64
nix build .#nixos-x86_64-image     # x86_64

# Or use just commands
just build-nixos-arm               # ARM64
just build-nixos-x86               # x86_64
```

### Run NixOS VMs

```shell
# Run with QEMU (aarch64 on Apple Silicon with HVF)
just run-nixos-arm

# Run x86_64 (Linux with KVM, or TCG emulation on macOS)
just run-nixos-x86
just run-nixos-x86-tcg    # Software emulation

# SSH into running VM (port 2223)
just ssh-nixos
```

### NixOS Configuration

The NixOS configuration lives in `nixos/`:
- `modules/base.nix` - Users, SSH, packages
- `modules/cloud-init.nix` - Cloud-init support
- `modules/qemu-guest.nix` - Virtio drivers
- `x86_64/` - x86_64-specific config (GRUB, ttyS0)
- `aarch64/` - aarch64-specific config (systemd-boot, ttyAMA0)

Same credentials as AlmaLinux: root/packer, admin/admin

### Setting Up Lima as aarch64-linux Builder (macOS)

NixOS disk images cannot cross-compile - they must be built on native architecture. On macOS Apple Silicon, use Lima as an aarch64-linux builder:

**1. Start Lima and install Nix:**

```shell
limactl start default
lima bash -c "curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes"
```

**2. Enable root SSH access and configure Nix:**

```shell
lima sudo bash -c "mkdir -p /root/.ssh && cp ~/.ssh/authorized_keys /root/.ssh/ && chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys"
lima sudo bash -c '. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && cat >> /etc/nix/nix.conf << EOF
trusted-users = root
system-features = kvm nixos-test benchmark big-parallel uid-range
EOF
systemctl restart nix-daemon'
```

**3. Add SSH config** (append to `/etc/ssh/ssh_config`):

```shell
sudo tee -a /etc/ssh/ssh_config << 'EOF'

# Lima builder for Nix
Host lima-builder
    HostName 127.0.0.1
    Port 60022
    User root
    IdentityFile /Users/YOUR_USERNAME/.lima/_config/user
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
```

**4. Configure Nix machines file** (`~/.config/nix/machines`):

```
ssh-ng://lima-builder aarch64-linux - 4 1 kvm,nixos-test,benchmark,big-parallel -
```

**5. Configure Nix to use builders** (`~/.config/nix/nix.conf`):

```
builders = @/Users/YOUR_USERNAME/.config/nix/machines
builders-use-substitutes = true
```

**6. Build aarch64 images:**

```shell
limactl start default  # Ensure Lima is running
nix build .#nixos-aarch64-image
```

## Project Structure

```
├── flake.nix                           # Nix flake with devShells & nixosConfigurations
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
├── nixos/
│   ├── modules/                        # Shared NixOS modules
│   │   ├── base.nix                    # Users, SSH, packages
│   │   ├── cloud-init.nix              # Cloud-init configuration
│   │   └── qemu-guest.nix              # Virtio drivers, guest agent
│   ├── x86_64/                         # x86_64 NixOS config
│   │   ├── default.nix                 # Main config + make-disk-image
│   │   └── hardware.nix                # GRUB, ttyS0
│   ├── aarch64/                        # aarch64 NixOS config
│   │   ├── default.nix                 # Main config + make-disk-image
│   │   └── hardware.nix                # systemd-boot, ttyAMA0
│   └── output/                         # Built images (gitignored)
└── README.md
```

## Available Commands

Run `just` to see all commands. Key ones:

```
AlmaLinux - Packer (x86_64):
  just build-alma-x86     # Build x86_64 image (requires KVM)
  just run-alma-x86       # Run x86_64 image

AlmaLinux - Packer (aarch64):
  just build-alma-arm     # Build ARM64 image
  just run-alma-arm       # Run ARM64 image

NixOS (builds via remote builder from macOS):
  just build-nixos-x86    # Build x86_64 NixOS image
  just build-nixos-arm    # Build aarch64 NixOS image
  just run-nixos-x86      # Run x86_64 image (KVM)
  just run-nixos-arm      # Run aarch64 image (HVF)
  just ssh-nixos          # SSH into NixOS VM (port 2223)

Lima (macOS - RECOMMENDED for quick local VMs):
  just lima-start         # Start AlmaLinux 10 VM
  just lima-shell         # Shell into Lima VM
  just lima-stop          # Stop Lima VM

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
  just ssh-alma           # SSH into AlmaLinux VM (port 2222)
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
