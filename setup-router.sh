#!/bin/bash

# Function to check the last command's exit status
check_error() {
  if [ $? -ne 0 ]; then
    echo "Error: $1 failed. Exiting..."
    exit 1
  fi
}

# Update and Upgrade System
sudo apt-get update && sudo apt-get upgrade -y
check_error "System update and upgrade"

# Install Necessary Software
sudo apt install -y hostapd dnsmasq
check_error "Software installation"

# Configure Hostapd
sudo tee /etc/hostapd/hostapd.conf > /dev/null <<EOL
interface=wlan0
driver=nl80211
ssid=Miao_Router
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=password
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOL
check_error "Hostapd configuration"

# Configure Hostapd Daemon
echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' | sudo tee -a /etc/default/hostapd > /dev/null
check_error "Hostapd Daemon configuration"

# Configure DNSMasq
sudo tee /etc/dnsmasq.conf > /dev/null <<EOL
interface=wlan0
bind-dynamic
domain-needed
bogus-priv
dhcp-range=192.168.20.100,192.168.20.200,255.255.255.0,12h
EOL
check_error "DNSMasq configuration"

# Configure DHCP Server
sudo tee -a /etc/dhcpcd.conf > /dev/null <<EOL
nohook wpa_supplicant
interface wlan0
static ip_address=192.168.20.10/24
static routers=192.168.20.1
EOL
check_error "DHCP Server configuration"

# Enable IP Forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf > /dev/null
sudo sysctl -p
check_error "IP Forwarding enable"

# Add NAT rules to iptables
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
check_error "NAT rules configuration"

# Add iptables to rc.local for persistence
echo "iptables-restore < /etc/iptables.ipv4.nat" | sudo tee -a /etc/rc.local > /dev/null
check_error "Iptables persistence"

echo "Configuration completed successfully."
