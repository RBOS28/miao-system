#!/bin/bash
set -e  # Exit the script if any command fails

echo "Starting to update system..."
if ! sudo apt-get update; then
  echo "Failed to update packages"
  exit 1
fi
if ! sudo apt-get upgrade -y; then
  echo "Failed to upgrade packages"
  exit 1
fi
echo "System update complete."

echo "Installing hostapd and dnsmasq..."
if ! sudo apt install -y hostapd dnsmasq; then
  echo "Failed to install required packages"
  exit 1
fi
echo "Installation complete."

echo "Configuring Hostapd..."
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
echo "Hostapd configuration complete."

echo "Configuring Hostapd Daemon..."
echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' | sudo tee -a /etc/default/hostapd > /dev/null
if systemctl is-enabled --quiet hostapd; then
  echo "hostapd service is already enabled"
else
  if systemctl is-active --quiet hostapd; then
    echo "hostapd service is running"
  else
    if systemctl is-failed --quiet hostapd; then
      sudo systemctl reset-failed hostapd
    fi
    if systemctl is-enabled --quiet hostapd; then
      sudo systemctl disable hostapd
    fi
	sudo systemctl unmask hostapd
	sudo systemctl enable hostapd
  fi
fi 
echo "Hostapd Daemon configuration complete."

echo "Configuring DNSMasq..."
sudo tee /etc/dnsmasq.conf > /dev/null <<EOL
interface=wlan0
bind-dynamic
domain-needed
bogus-priv
dhcp-range=192.168.20.100,192.168.20.200,255.255.255.0,12h
EOL
echo "DNSMasq configuration complete."

echo "Configuring DHCP Server..."
sudo tee -a /etc/dhcpcd.conf > /dev/null <<EOL
nohook wpa_supplicant
interface wlan0
static ip_address=192.168.20.10/24
static routers=192.168.20.1
EOL
echo "DHCP Server configuration complete."

echo "Enabling IP Forwarding..."
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf > /dev/null
sudo sysctl -p
echo "IP Forwarding enabled."

echo "Configuring NAT rules..."
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
echo "NAT rules configuration complete."

echo "Configuring Iptables persistence..."
echo "iptables-restore < /etc/iptables.ipv4.nat" | sudo tee -a /etc/rc.local > /dev/null
echo "Iptables persistence complete."

echo "Setup complete. Your Raspberry Pi should now function as a router."

