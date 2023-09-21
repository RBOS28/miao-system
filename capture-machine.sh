#!/bin/bash

# Exit on any error
set -e

# Function to check if a command exists
command_exists () {
  type "$1" &> /dev/null;
}

# Define log file
LOG_DIR="$HOME/miao-system"
LOG_FILE="$LOG_DIR/log-file.log"

# Create log directory if it doesn't exist
mkdir -p $LOG_DIR 

# Create or truncate the log file
: > $LOG_FILE 

# Add debugging information to log file
echo "About to create log directory and file..." | tee -a $LOG_FILE
echo "Log directory and file shuold now be created." | tee -a $LOG_FILE 

# Check if tcpdump is installed, if not install it
if ! command_exists tcpdump ; then
  echo "tcpdump not found. Installing..." | tee -a $LOG_FILE
  sudo apt-get update
  sudo apt-get install -y tcpdump
fi

# Check if tshark is installed, if not install it
if ! command_exists tshark ; then
  echo "tshark not found. Installing..." | tee -a $LOG_FILE
  sudo apt-get update
  sudo apt-get install -y tshark
fi

# Update and Upgrade
echo "Starting to update system..." | tee -a $LOG_FILE
if ! sudo apt-get update; then
  echo "Failed to update packages" | tee -a $LOG_FILE
  exit 1
fi
if ! sudo apt-get upgrade -y; then
  echo "Failed to upgrade packages" | tee -a $LOG_FILE
  exit 1
fi
echo "System update complete." | tee -a $LOG_FILE

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
    echo "Failed to capture packets on $INTERFACE." | tee -a $LOG_FILE
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
    -E occurrence=f
	> "$CSV"; then
    echo "Failed to convert PCAP to CSV for $INTERFACE." | tee -a $LOG_FILE
    ALL_SUCCESS=false
  fi
done

if [ "$ALL_SUCCESS" = true ]; then
  echo "Data collection, backup, and conversion to CSV completed." | tee -a $LOG_FILE
else
  echo "Some operations failed. Check the log for details." | tee -a $LOG_FILE
fi

