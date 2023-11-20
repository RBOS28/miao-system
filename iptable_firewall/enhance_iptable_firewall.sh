#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Define your network interface names
WAN_INTERFACE="eth0"  # Replace with your actual WAN interface name
LAN_INTERFACE="eth1"  # Replace with your actual LAN interface name

# Flush existing rules and set chain policies setting default policy to DROP
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback access
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established and related connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# NAT configuration
iptables -t nat -A POSTROUTING -o $WAN_INTERFACE -j MASQUERADE

# Forward traffic from LAN to WAN
iptables -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE -j ACCEPT

# Allow specific ports/services (SSH, HTTP, HTTPS)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT   # SSH
iptables -A INPUT -p tcp --dport 80 -j ACCEPT   # HTTP
iptables -A INPUT -p tcp --dport 443 -j ACCEPT  # HTTPS

# Advanced Port Forwarding (example)
# iptables -t nat -A PREROUTING -i $WAN_INTERFACE -p tcp --dport [external_port] -j DNAT --to [internal_ip]:[internal_port]
# iptables -A FORWARD -p tcp -d [internal_ip] --dport [internal_port] -j ACCEPT

# Rate limiting for SYN packets to prevent SYN flood attack
iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT

# Drop invalid packets
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Logging dropped packets
iptables -N LOGGING
iptables -A INPUT -j LOGGING
iptables -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "iptables dropped: " --log-level 4
iptables -A LOGGING -j DROP

# Optional: ICMP (ping) rules
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT

# Drop XMAS and NULL packets
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# Limit connections per IP to prevent brute force attacks
iptables -A INPUT -p tcp --syn -m connlimit --connlimit-above 10 -j DROP

# Save the rules
iptables-save > /etc/iptables/rules.v4

echo "Firewall rules set and saved."

