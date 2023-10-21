#!/bin/bash

while true; do
    clear
    echo "Scanning the network on eth0 (192.168.58.0/24)..."
    nmap -sn 192.168.58.0/24
    echo "Trying to identify operating systems on eth0..."
    nmap -O 192.168.58.0/24
    echo "-------------------------------"
    echo "Scanning the network on wlan0 (192.168.20.0/24)..."
    nmap -sn 192.168.20.0/24
    echo "Trying to identify operating systems on wlan0..."
    nmap -O 192.168.20.0/24
    sleep 60
done
