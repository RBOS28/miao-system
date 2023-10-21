#!/bin/bash

# Set the subnet for wlan0
wlan0_subnet="192.168.20.0/24"

# Temporary file to store host IPs and OS
temp_file="temp_output.txt"

# Scan for hosts on wlan0
echo "Scanning for hosts connected to wlan0..."
sudo nmap -sn -O $wlan0_subnet -oG - | awk '/Up$/{print $2}' > wlan0_hosts.txt

# Count and list the hosts connected to wlan0
wlan0_count=$(wc -l < wlan0_hosts.txt)
echo "Number of hosts connected to wlan0: $wlan0_count"
echo "Hosts:"
cat wlan0_hosts.txt

# Check if no hosts are found and exit if so
if [ $wlan0_count -eq 0 ]; then
    echo "No hosts found. Exiting."
    exit 0
else
    # Scan again, but this time also attempt to identify the OS
    sudo nmap -O -iL wlan0_hosts.txt -oG $temp_file
    awk '/Nmap scan report for/ {printf $5;printf " "}; /Running:/ {print $2}' $temp_file > wlan0_hosts_with_os.txt
    
    echo "Hosts with OS:"
    cat wlan0_hosts_with_os.txt

    # Clean up temporary files
    rm $temp_file
fi

