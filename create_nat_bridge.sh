#!/usr/bin/env bash

# Setup dummy interface.
VIRTUAL_MAC=$(hexdump -vn3 -e '/3 "52:54:00"' -e '/1 ":%02x"' -e '"\n"' /dev/urandom)
sudo ip link add virbr10-dummy address "$VIRTUAL_MAC" type dummy

# Setup bridge.
sudo brctl addbr virbr10
sudo brctl stp virbr10 on
sudo brctl addif virbr10 virbr10-dummy
sudo ip address add 192.168.187.1/24 dev virbr10 broadcast 192.168.187.255

# Enable Forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.conf.all.forwarding=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Setup forwarding rules
# TODO convert to iptables commands
sudo iptables-restore < forwarding.iptables
sudo iptables-restore < nat.iptables
sudo iptables-restore < mangle.iptables


# Setup DNSmasq
sudo mkdir -p /var/lib/dnsmasq/virbr10
sudo touch /var/lib/dnsmasq/virbr10/hostsfile
sudo touch /var/lib/dnsmasq/virbr10/leases

# Drop dnsmasq config
sudo cp dnsmasq.conf /var/lib/dnsmasq/virbr10/dnsmasq.conf


# Disable virsh default network
virsh net-destroy default
virsh net-autostart --disable default


# Arch is missing this file
sudo mkdir -p /etc/qemu/
sudo touch /etc/qemu/bridge.conf
echo "allow all" | sudo tee /etc/qemu/"$USER".conf
echo "include /etc/qemu/$USER.conf" | sudo tee --append /etc/qemu/bridge.conf
sudo chown root:"$USER" /etc/qemu/"$USER".conf
sudo chmod 640 /etc/qemu/"$USER".conf

# 52:54:00:19:56:01


# <interface type="bridge">
#   <source bridge="virbr10"/>
#   <mac address="52:54:00:19:56:01"/>
# </interface>