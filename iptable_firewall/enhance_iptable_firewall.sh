#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Enable IP Forwarding
echo "Enabling IP Forwarding..."
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-ipforward.conf
sysctl -p /etc/sysctl.d/99-ipforward.conf

# Set up iptables rules
echo "Setting up iptables rules..."

# Flush existing rules and set chain policies
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# NAT configuration
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Forward traffic from wlan0 to eth0
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow specific services on wlan0 (like DHCP, DNS)
iptables -A INPUT -i wlan0 -p udp --dport 53 -j ACCEPT  # DNS
iptables -A INPUT -i wlan0 -p udp --dport 67 -j ACCEPT  # DHCP

# Save the rules
iptables-save > /etc/iptables/rules.v4

echo "Firewall rules set and saved."

# Install iptables-persistent for rule persistence
echo "Installing iptables-persistent..."
apt-get update
apt-get install -y iptables-persistent

# Save iptables rules
netfilter-persistent save

echo "Network setup complete."

