#!/bin/bash

# Set the subnet for wlan0
wlan0_subnet="192.168.20.0/24"

# Scan for hosts on wlan0
echo "Scanning for hosts connected to wlan0..."
nmap -sn $wlan0_subnet -oG - | awk '/Up$/{print $2}' > wlan0_hosts.txt

# Count and list the hosts connected to wlan0
wlan0_count=$(wc -l < wlan0_hosts.txt)
echo "Number of hosts connected to wlan0: $wlan0_count"
echo "Hosts:"
cat wlan0_hosts.txt

# Check if no hosts are found and exit if so
if [ $wlan0_count -eq 0 ]; then
    echo "No hosts found. Exiting."
    exit 0
fi
