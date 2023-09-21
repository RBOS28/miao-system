#!/bin/bash

set -e # Exit on any error

# Function to check if a command exists
command_exists () {
  type "$1" &> /dev/null;
}

# Check if tcpdump is installed, if not install it
if ! command_exists tcpdump ; then
  echo "tcpdump not found. Installing..."
  sudo apt-get update
  sudo apt-get install -y tcpdump
fi

# Check if tshark is installed, if not install it
if ! command_exists tshark ; then
  echo "tshark not found. Installing..."
  sudo apt-get update
  sudo apt-get install -y tshark
fi

# Directory to save the capture and backup files
CAPTURE_DIR="/path/to/save/pcap_files"
CSV_DIR="/path/to/save/csv_files"
BACKUP_DIR="/path/to/save/backup_pcap_files"

# Make sure the directories exist
mkdir -p $CAPTURE_DIR
mkdir -p $CSV_DIR
mkdir -p $BACKUP_DIR

# List of inteferences to capture ons
INTERFACES=("eth0" "wlan0") 

# Packet capture parameters
PACKET_COUNT=1000 

for INTERFACE in "${INTERFACES[@]}"; do
  # File name
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
    ALL_SUCCESS=false
  fi
done

if [ "$ALL_SUCCESS" = true ]; then
  echo "Data collection, backup, and conversion to CSV completed."
else
  echo "Some operations failed. Check the log for details."
fi

