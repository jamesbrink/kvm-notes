# KVM/QEMU VM Development Justfile
# Run `just` to see all available commands

# Default recipe - show help
default:
    @just --list

# ============================================================================
# Packer Commands
# ============================================================================

# Initialize packer plugins (run once)
packer-init:
    cd packer/almalinux10 && packer init .

# Validate packer configuration
packer-validate:
    cd packer/almalinux10 && packer validate .

# Build AlmaLinux 10 image (requires KVM - run on Linux)
build-alma: packer-init
    cd packer/almalinux10 && packer build -force .

# Build AlmaLinux 10 with visible console (not headless)
build-alma-debug: packer-init
    cd packer/almalinux10 && packer build -force -var headless=false .

# Build on macOS using software emulation (slow, for testing only)
build-alma-tcg: packer-init
    cd packer/almalinux10 && packer build -force -var accelerator=tcg -var headless=false .

# ============================================================================
# QEMU Direct Commands (Linux with KVM)
# ============================================================================

# Run the built AlmaLinux 10 image
run-alma:
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

# Run with VNC display
run-alma-vnc:
    @echo "Connect via VNC to localhost:5900"
    qemu-system-x86_64 \
        -machine q35,accel=kvm \
        -cpu host \
        -m 2048 \
        -smp 2 \
        -drive file=packer/almalinux10/output/almalinux10/almalinux10,format=qcow2,if=virtio \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -device virtio-net,netdev=net0 \
        -vnc :0

# SSH into running VM (assumes port 2222 forwarding)
ssh-alma:
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@localhost

# SSH as admin user
ssh-alma-admin:
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 admin@localhost

# ============================================================================
# Lima Commands (macOS)
# ============================================================================

# Start a Lima VM with AlmaLinux (uses cloud image)
lima-start:
    limactl start --name=almalinux template://almalinux-10

# Stop Lima VM
lima-stop:
    limactl stop almalinux

# Delete Lima VM
lima-delete:
    limactl delete almalinux

# Shell into Lima VM
lima-shell:
    limactl shell almalinux

# List Lima VMs
lima-list:
    limactl list

# ============================================================================
# Remote Build (via hal9000)
# ============================================================================

# Build on remote Linux host with KVM
remote-build host="hal9000":
    ssh {{host}} "cd $(pwd) && nix develop --command just build-alma"

# Sync project to remote and build
remote-sync-build host="hal9000":
    rsync -avz --exclude='.git' --exclude='packer_cache' --exclude='output' . {{host}}:~/kvm-notes/
    ssh {{host}} "cd ~/kvm-notes && nix develop --command just build-alma"

# Fetch built image from remote
remote-fetch host="hal9000":
    mkdir -p packer/almalinux10/output/almalinux10
    rsync -avz {{host}}:~/kvm-notes/packer/almalinux10/output/almalinux10/ packer/almalinux10/output/almalinux10/

# ============================================================================
# Utilities
# ============================================================================

# Download AlmaLinux boot ISO
iso-download:
    mkdir -p iso
    curl -L -o iso/AlmaLinux-10.1-x86_64-boot.iso \
        https://repo.almalinux.org/almalinux/10.1/isos/x86_64/AlmaLinux-10.1-x86_64-boot.iso
    @echo "ISO downloaded to iso/AlmaLinux-10.1-x86_64-boot.iso"

# Verify ISO checksum
iso-verify:
    @echo "Expected: 68a9e14fa252c817d11a3c80306e5a21b2db37c21173fd3f52a9eb6ced25a4a0"
    @echo "Actual:   $(sha256sum iso/AlmaLinux-10.1-x86_64-boot.iso | cut -d' ' -f1)"

# Clean all build artifacts
clean:
    rm -rf packer/almalinux10/output
    rm -rf .packer_cache
    rm -rf packer_cache

# Clean ISO cache
clean-iso:
    rm -rf iso

# Show image info
image-info:
    qemu-img info packer/almalinux10/output/almalinux10/almalinux10

# Convert image to raw format
image-convert-raw:
    qemu-img convert -f qcow2 -O raw \
        packer/almalinux10/output/almalinux10/almalinux10 \
        packer/almalinux10/output/almalinux10/almalinux10.raw

# ============================================================================
# Libvirt Commands (Linux)
# ============================================================================

# Import image into libvirt
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
