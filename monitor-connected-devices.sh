#!/bin/bash

# Function to scan network and return number of hosts found
scan_network() {
    subnet=$1
    nmap_output=$(nmap -sn $subnet)
    echo "$nmap_output"
    num_hosts=$(echo "$nmap_output" | grep "Nmap scan report for" | wc -l)
    return $num_hosts
}

# Function to identify operating systems and display it
identify_os() {
    subnet=$1
    nmap -O $subnet
}

hosts_found_eth0=0
hosts_found_wlan0=0

# Scan the eth0 subnet
echo "Scanning the network on eth0 (192.168.58.0/24)..."
scan_network "192.168.58.0/24"
hosts_found_eth0=$?
if [ $hosts_found_eth0 -gt 0 ]; then
    echo "Trying to identify operating systems on eth0..."
    identify_os "192.168.58.0/24"
fi

echo "-------------------------------"

# Scan the wlan0 subnet
echo "Scanning the network on wlan0 (192.168.20.0/24)..."
scan_network "192.168.20.0/24"
hosts_found_wlan0=$?
if [ $hosts_found_wlan0 -gt 0 ]; then
    echo "Trying to identify operating systems on wlan0..."
    identify_os "192.168.20.0/24"
fi

# Stop the script if no hosts were found on either subnet
if [ $hosts_found_eth0 -eq 0 ] && [ $hosts_found_wlan0 -eq 0 ]; then
    echo "No hosts found on either subnet. Exiting."
    exit 0
fi

