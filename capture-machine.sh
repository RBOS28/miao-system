#!/bin/bash

set -e # Exit on any error

# Directory to save the capture and backup files
CAPTURE_DIR="/path/to/save/pcap_files"
CSV_DIR="/path/to/save/csv_files"
BACKUP_DIR="/path/to/save/backup_pcap_files"

# Make sure the directories exist
mkdir -p $CAPTURE_DIR
mkdir -p $CSV_DIR
mkdir -p $BACKUP_DIR

# List of inteferences to capture ons
INTERFACES=("eth0" "wlan0")  # Array of interfaces

# Packet capture parameters
PACKET_COUNT=1000  # Set the number of packets you want to capture

for INTERFACE in "${INTERFACES[@]}"; do
  # File names
  PCAP="$CAPTURE_DIR/${INTERFACE}_traffic.pcap"
  CSV="$CSV_DIR/${INTERFACE}_traffic.csv"
  BACKUP="$BACKUP_DIR/${INTERFACE}_traffic_backup.pcap"

  # Capture packets
  if ! sudo tcpdump -i $INTERFACE -c $PACKET_COUNT -w "$PCAP"; then
    echo "Failed to capture packets on $INTERFACE."
    continue
  fi

  # Backup the PCAP file
  cp $PCAP $BACKUP

  # Convert the PCAP to CSV format
  if ! tshark -r "$PCAP" -T fields \
    -e ip.src \
    -e ip.dst \
    -e tcp.srcport \
    -e tcp.dstport \
    -e udp.srcport \
    -e udp.dstport \
    -e frame.time_epoch \
    -e _ws.col.Protocol \
    -e frame.len \
    -e dns.qry.name \
    -e http.request.method \
    -e http.request.uri \
    -e http.response.code \
    -e frame.interface_id \
    -e frame.direction \
    -e frame.cap_len \
    -E header=y \
    -E separator=, \
    -E quote=d \
    -E occurrence=f > "$CSV"; then
    echo "Failed to convert PCAP to CSV for $INTERFACE."
    continue
  fi
done

echo "Data collection, backup, and conversion to CSV completed."
