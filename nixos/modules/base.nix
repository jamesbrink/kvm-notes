# Base NixOS configuration for VM images
# Common settings shared between x86_64 and aarch64 builds
#
# This mirrors the AlmaLinux kickstart configuration for consistency:
# - Same credentials (root/packer, admin/admin)
# - Same SSH settings (root login enabled)
# - Same basic package set
{ config, lib, pkgs, ... }:

{
  # NixOS release version
  system.stateVersion = "24.11";

  # Timezone - UTC for server/cloud VMs
  time.timeZone = "UTC";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";

  # Networking - use networkd for modern network management
  networking = {
    # Hostname can be overridden by cloud-init
    hostName = lib.mkDefault "nixos";

    # Use DHCP by default (works with QEMU user networking and cloud environments)
    useDHCP = lib.mkDefault true;

    # Use networkd for network management (avoids conflict with dhcpcd)
    useNetworkd = true;

    # Firewall disabled for dev builds (enable in production)
    firewall.enable = lib.mkDefault false;
  };

  # Enable systemd-networkd
  systemd.network.enable = true;

  # Root user - password matches AlmaLinux builds for consistency
  # In production: Remove initialPassword and use SSH keys via cloud-init
  users.users.root = {
    initialPassword = "packer";
  };

  # Admin user - matches AlmaLinux kickstart configuration
  # Has passwordless sudo access for provisioning
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "admin";
  };

  # Passwordless sudo for wheel group (matches AlmaLinux kickstart)
  security.sudo.wheelNeedsPassword = false;

  # SSH server configuration
  services.openssh = {
    enable = true;
    settings = {
      # Allow root login for packer-style provisioning
      # In production: Set to "prohibit-password" or "no"
      PermitRootLogin = "yes";

      # Password authentication for initial access
      # In production: Disable and use SSH keys only
      PasswordAuthentication = true;
    };
  };

  # Essential packages - mirrors AlmaLinux kickstart package selection
  environment.systemPackages = with pkgs; [
    vim           # Text editor
    wget          # HTTP downloader
    curl          # HTTP client
    rsync         # File synchronization
    htop          # Process viewer
    git           # Version control
    tmux          # Terminal multiplexer
    jq            # JSON processor
  ];

  # Enable nix flakes (useful for NixOS VMs)
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
