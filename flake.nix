{
  description = "KVM/QEMU VM development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        isDarwin = pkgs.stdenv.isDarwin;
        isLinux = pkgs.stdenv.isLinux;

        # Common packages for all platforms
        commonPackages = with pkgs; [
          # Task runner
          just

          # Packer for building VM images
          packer

          # Cloud-init tools for creating NoCloud ISOs
          cloud-utils

          # Disk image utilities
          qemu-utils

          # SSH and network tools
          openssh
          curl
          wget

          # JSON/YAML processing
          jq
          yq-go
        ];

        # macOS-specific packages
        darwinPackages = with pkgs; [
          # QEMU with HVF (Hypervisor.framework) support
          qemu

          # Lima - Linux VMs on macOS with file sharing & port forwarding
          lima

          # Utilities
          coreutils
          gnused
          gawk
        ];

        # Linux-specific packages (for hal9000 or any Linux host)
        linuxPackages = with pkgs; [
          # QEMU with KVM support
          qemu_kvm

          # Libvirt stack
          libvirt
          virt-manager
          virt-viewer

          # UEFI firmware for VMs
          OVMF

          # TPM emulation (for Windows VMs)
          swtpm

          # Virsh and virt-install
          libguestfs

          # Network utilities
          bridge-utils
          dnsmasq
          iptables
        ];

        # Select packages based on platform
        platformPackages =
          if isDarwin then darwinPackages
          else if isLinux then linuxPackages
          else [ ];

        allPackages = commonPackages ++ platformPackages;

      in
      {
        devShells.default = pkgs.mkShell {
          name = "kvm-dev";

          buildInputs = allPackages;

          shellHook = ''
            echo "🖥️  KVM/QEMU Development Environment"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            ${if isDarwin then ''
              echo "Platform: macOS (QEMU + HVF, Lima available)"
              echo ""
              echo "Quick start:"
              echo "  just build-alma    # Build AlmaLinux 10 image (on Linux/remote)"
              echo "  just lima-start    # Start Lima VM"
              echo ""
              echo "For KVM acceleration, use remote builder:"
              echo "  ssh hal9000 'cd /path/to/kvm-notes && just build-alma'"
            '' else ''
              echo "Platform: Linux (QEMU + KVM)"
              echo ""
              echo "Quick start:"
              echo "  just build-alma    # Build AlmaLinux 10 image"
              echo "  just run-alma      # Run the built image"
              echo "  just ssh-alma      # SSH into running VM"
            ''}
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Available tools:"
            echo "  packer --version"
            echo "  qemu-system-x86_64 --version"
            ${if isDarwin then ''
              echo "  limactl --version"
            '' else ''
              echo "  virsh --version"
              echo "  virt-install --version"
            ''}
            echo ""
          '';

          # Environment variables
          PACKER_CACHE_DIR = ".packer_cache";
        } // (if isLinux then {
          LIBVIRT_DEFAULT_URI = "qemu:///system";
          OVMF_PATH = "${pkgs.OVMF.fd}/FV";
        } else { });

        # Expose packages for remote builds
        packages = {
          inherit (pkgs) packer qemu;
        } // (if isLinux then {
          inherit (pkgs) libvirt OVMF;
        } else { });
      }
    ) // {
      # NixOS module for hal9000 or other NixOS hosts
      nixosModules.vm-host = { config, pkgs, ... }: {
        virtualisation.libvirtd = {
          enable = true;
          qemu = {
            package = pkgs.qemu_kvm;
            ovmf.enable = true;
            swtpm.enable = true;
          };
        };

        # Allow users in libvirtd group to manage VMs
        users.groups.libvirtd = { };

        # Firewall rules for VM networking
        networking.firewall.trustedInterfaces = [ "virbr0" ];
      };
    };
}
