# KVM/QEMU VM Development Justfile
# Run `just` to see all available commands

# Use bash for shell commands
set shell := ["bash", "-cu"]

# EFI firmware path - auto-detect from QEMU location (works with nix)
efi_aarch64 := env_var_or_default("QEMU_EFI_AARCH64", `dirname $(which qemu-system-aarch64)`+ "/../share/qemu/edk2-aarch64-code.fd")

# Default recipe - show help
default:
    @just --list

# ============================================================================
# Formatting & Linting
# ============================================================================

# Format all HCL files
fmt:
    packer fmt -recursive packer/

# Check HCL formatting (no changes)
fmt-check:
    packer fmt -check -recursive packer/

# Validate all packer configs
lint:
    @echo "Validating x86_64..."
    cd packer/almalinux10/x86_64 && packer validate .
    @echo "Validating aarch64..."
    cd packer/almalinux10/aarch64 && packer validate -var efi_firmware="{{efi_aarch64}}" .

# ============================================================================
# AlmaLinux 10 x86_64 (for Linux KVM or remote builds)
# ============================================================================

# Initialize packer plugins for x86_64
packer-init-x86:
    cd packer/almalinux10/x86_64 && packer init .

# Validate x86_64 packer configuration
packer-validate-x86:
    cd packer/almalinux10/x86_64 && packer validate .

# Build AlmaLinux 10 x86_64 (requires KVM - run on Linux)
build-alma-x86: packer-init-x86
    cd packer/almalinux10/x86_64 && packer build -force .

# Build x86_64 with visible console
build-alma-x86-debug: packer-init-x86
    cd packer/almalinux10/x86_64 && packer build -force -var headless=false .

# Build x86_64 with TCG (software emulation - VERY slow)
build-alma-x86-tcg: packer-init-x86
    cd packer/almalinux10/x86_64 && packer build -force -var accelerator=tcg -var cpu_type=qemu64 -var headless=false .

# Run x86_64 image (Linux with KVM)
run-alma-x86:
    qemu-system-x86_64 \
        -machine q35,accel=kvm \
        -cpu host \
        -m 2048 \
        -smp 2 \
        -drive file=packer/almalinux10/output/almalinux10/almalinux10,format=qcow2,if=virtio \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -device virtio-net,netdev=net0 \
        -display none \
        -serial mon:stdio

# Run x86_64 with TCG emulation (macOS - slow)
run-alma-x86-tcg:
    qemu-system-x86_64 \
        -machine q35,accel=tcg \
        -cpu qemu64 \
        -m 2048 \
        -smp 2 \
        -drive file=packer/almalinux10/output/almalinux10/almalinux10,format=qcow2,if=virtio \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -device virtio-net,netdev=net0 \
        -nographic

# ============================================================================
# AlmaLinux 10 aarch64 (native on Apple Silicon with HVF)
# ============================================================================

# Initialize packer plugins for aarch64
packer-init-arm:
    cd packer/almalinux10/aarch64 && packer init .

# Validate aarch64 packer configuration
packer-validate-arm:
    cd packer/almalinux10/aarch64 && packer validate -var efi_firmware="{{efi_aarch64}}" .

# Build AlmaLinux 10 aarch64 (macOS Apple Silicon with HVF)
build-alma-arm: packer-init-arm
    cd packer/almalinux10/aarch64 && packer build -force -var efi_firmware="{{efi_aarch64}}" .

# Build aarch64 with visible console
build-alma-arm-debug: packer-init-arm
    cd packer/almalinux10/aarch64 && packer build -force -var efi_firmware="{{efi_aarch64}}" -var headless=false .

# Run aarch64 image (macOS with HVF - native speed)
run-alma-arm:
    qemu-system-aarch64 \
        -machine virt,accel=hvf \
        -cpu host \
        -m 2048 \
        -smp 2 \
        -bios "{{efi_aarch64}}" \
        -drive file=packer/almalinux10/output/almalinux10-aarch64/almalinux10-aarch64,format=qcow2,if=virtio \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -device virtio-net,netdev=net0 \
        -nographic

# Run aarch64 with VNC display
run-alma-arm-vnc:
    @echo "Connect via VNC to localhost:5900"
    qemu-system-aarch64 \
        -machine virt,accel=hvf \
        -cpu host \
        -m 2048 \
        -smp 2 \
        -bios "{{efi_aarch64}}" \
        -drive file=packer/almalinux10/output/almalinux10-aarch64/almalinux10-aarch64,format=qcow2,if=virtio \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -device virtio-net,netdev=net0 \
        -device virtio-gpu-pci \
        -vnc :0

# ============================================================================
# Convenience Aliases (auto-detect or default)
# ============================================================================

# Build AlmaLinux (defaults to x86_64 for remote/Linux builds)
build-alma: build-alma-x86

# Run AlmaLinux (defaults to x86_64)
run-alma: run-alma-x86

# SSH into running VM (assumes port 2222 forwarding)
ssh-alma:
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@localhost

# SSH as admin user
ssh-alma-admin:
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 admin@localhost

# ============================================================================
# Lima Commands (macOS - RECOMMENDED for local ARM VMs)
# Lima uses cloud images with VZ framework - fast and reliable on Apple Silicon
# ============================================================================

# Start AlmaLinux 10 VM (recommended for local ARM development)
lima-start:
    @echo "Starting AlmaLinux 10 Lima VM..."
    limactl start --name=almalinux template://almalinux-10
    @echo ""
    @echo "VM started! Use 'just lima-shell' to connect"

# Start with custom resources
lima-start-large:
    limactl start --name=almalinux --cpus=4 --memory=8 template://almalinux-10

# Stop Lima VM
lima-stop:
    limactl stop almalinux

# Delete Lima VM
lima-delete:
    limactl delete almalinux

# Shell into Lima VM
lima-shell:
    limactl shell almalinux

# Run command in Lima VM
lima-run *cmd:
    limactl shell almalinux -- {{cmd}}

# SSH into Lima VM (alternative to shell)
lima-ssh:
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -i ~/.lima/almalinux/ssh/id_rsa \
        -p $(limactl show-ssh --format=port almalinux) \
        $(limactl show-ssh --format=user almalinux)@127.0.0.1

# Get Lima VM info
lima-info:
    limactl list
    @echo ""
    limactl show-ssh almalinux 2>/dev/null || true

# List available Lima templates
lima-templates:
    limactl start --list-templates | grep -E "(alma|rocky|centos|fedora)"

# ============================================================================
# Remote Build (via hal9000 or other Linux host)
# ============================================================================

# Sync project to remote and build x86_64
remote-sync-build host="hal9000":
    rsync -avz --exclude='.git' --exclude='.packer_cache' --exclude='output' . {{host}}:~/kvm-notes/
    ssh {{host}} "cd ~/kvm-notes && nix develop --command just build-alma-x86"

# Fetch built x86_64 image from remote
remote-fetch-x86 host="hal9000":
    mkdir -p packer/almalinux10/output/almalinux10
    rsync -avz {{host}}:~/kvm-notes/packer/almalinux10/output/almalinux10/ packer/almalinux10/output/almalinux10/

# Fetch built aarch64 image from remote (if building on ARM Linux)
remote-fetch-arm host="hal9000":
    mkdir -p packer/almalinux10/output/almalinux10-aarch64
    rsync -avz {{host}}:~/kvm-notes/packer/almalinux10/output/almalinux10-aarch64/ packer/almalinux10/output/almalinux10-aarch64/

# ============================================================================
# Utilities
# ============================================================================

# Download AlmaLinux x86_64 boot ISO
iso-download-x86:
    mkdir -p iso
    curl -L -o iso/AlmaLinux-10.1-x86_64-boot.iso \
        https://repo.almalinux.org/almalinux/10.1/isos/x86_64/AlmaLinux-10.1-x86_64-boot.iso
    @echo "ISO downloaded to iso/AlmaLinux-10.1-x86_64-boot.iso"

# Download AlmaLinux aarch64 boot ISO
iso-download-arm:
    mkdir -p iso
    curl -L -o iso/AlmaLinux-10.1-aarch64-boot.iso \
        https://repo.almalinux.org/almalinux/10.1/isos/aarch64/AlmaLinux-10.1-aarch64-boot.iso
    @echo "ISO downloaded to iso/AlmaLinux-10.1-aarch64-boot.iso"

# Clean all build artifacts
clean:
    rm -rf packer/almalinux10/output
    rm -rf .packer_cache
    rm -rf packer_cache

# Clean ISO cache
clean-iso:
    rm -rf iso

# Show x86_64 image info
image-info-x86:
    qemu-img info packer/almalinux10/output/almalinux10/almalinux10

# Show aarch64 image info
image-info-arm:
    qemu-img info packer/almalinux10/output/almalinux10-aarch64/almalinux10-aarch64

# ============================================================================
# VNC Commands (for debugging packer builds)
# ============================================================================

# Open VNC viewer to packer VM (password: password)
vnc port="5900":
    @echo "Connecting to VNC on port {{port}}... (Password: password)"
    vncviewer "localhost:{{port}}"

# Find QEMU VNC port and connect
vnc-find:
    #!/usr/bin/env bash
    set -eu
    port=$(lsof -i :5900-5999 2>/dev/null | grep qemu | grep LISTEN | awk '{print $9}' | cut -d: -f2 | head -1)
    if [ -n "$port" ]; then
        echo "Found QEMU VNC on port $port (Password: password)"
        vncviewer "localhost:$port"
    else
        echo "No QEMU VNC ports found"
        exit 1
    fi

# List active QEMU VNC ports
vnc-list:
    @echo "Active QEMU VNC ports:"
    @lsof -i :5900-5999 2>/dev/null | grep qemu | grep LISTEN || echo "No QEMU VNC ports found"

# ============================================================================
# Libvirt Commands (Linux)
# ============================================================================

# Import x86_64 image into libvirt
libvirt-import:
    virt-install \
        --name almalinux10 \
        --memory 2048 \
        --vcpus 2 \
        --disk path=packer/almalinux10/output/almalinux10/almalinux10,format=qcow2 \
        --import \
        --os-variant almalinux9 \
        --network network=default \
        --graphics vnc \
        --noautoconsole

# List libvirt VMs
libvirt-list:
    virsh list --all

# Start libvirt VM
libvirt-start:
    virsh start almalinux10

# Stop libvirt VM
libvirt-stop:
    virsh shutdown almalinux10

# Force stop libvirt VM
libvirt-destroy:
    virsh destroy almalinux10

# Remove libvirt VM (keeps disk)
libvirt-undefine:
    virsh undefine almalinux10

# Console into libvirt VM
libvirt-console:
    virsh console almalinux10
