#!/bin/bash

# Variables
PACKET_COUNT=10
PCAP_FILE="simple_test.pcap"
CSV_FILE="simple_test.csv"

# Capture Packets
echo "Capturing $PACKET_COUNT packets..."
sudo tcpdump -i eth0 -c $PACKET_COUNT -w $PCAP_FILE

# Convert PCAP to CSV
echo "Converting $PCAP_FILE to CSV format..."
tshark -r $PCAP_FILE -T fields -e ip.src -e ip.dst -E header=y -E separator=, -E quote=d -E occurrence=f > $CSV_FILE

# Output to user
echo "Done! Files created:"
echo "- $PCAP_FILE"
echo "- $CSV_FILE"
