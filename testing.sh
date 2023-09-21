#!/bin/bash

# Exit on any error
set -e

# Log info function for easy logging
log_info() {
  echo "$1" | sudo tee -a $LOG_FILE
}

# Function to check if a command exists
command_exists() {
  type "$1" &> /dev/null;
}

# Define log file
LOG_DIR="$HOME/miao-system"
LOG_FILE="$LOG_DIR/log-file.log"

# Create log directory if it doesn't exist
sudo mkdir -p $LOG_DIR

# Create or truncate the log file
sudo : > $LOG_FILE

log_info "About to create log directory and file..."
log_info "Log directory and file should now be created."

# Check if tcpdump and tshark are installed, if not install them
for tool in tcpdump tshark; do
  if ! command_exists $tool; then
    log_info "$tool not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y $tool
  fi
done

# Update and Upgrade
log_info "Starting to update system..."
if ! sudo apt-get update; then
  log_info "Failed to update packages"
  exit 1
fi
if ! sudo apt-get upgrade -y; then
  log_info "Failed to upgrade packages"
  exit 1
fi
log_info "System update complete."

# Directory paths
CAPTURE_DIR="/path/to/save/pcap_files"
CSV_DIR="/path/to/save/csv_files"
BACKUP_DIR="/path/to/save/backup_pcap_files"

# Ensure the directories exist
for dir in $CAPTURE_DIR $CSV_DIR $BACKUP_DIR; do
  sudo mkdir -p $dir
done

# List of interfaces to capture on
INTERFACES=("eth0" "wlan0")
PACKET_COUNT=1000
ALL_SUCCESS=true

for INTERFACE in "${INTERFACES[@]}"; do
  PCAP="$CAPTURE_DIR/${INTERFACE}_traffic.pcap"
  CSV="$CSV_DIR/${INTERFACE}_traffic.csv"
  BACKUP="$BACKUP_DIR/${INTERFACE}_traffic_backup.pcap"

  # Capture packets
  if ! sudo tcpdump -i $INTERFACE -c $PACKET_COUNT -w "$PCAP"; then
    log_info "Failed to capture packets on $INTERFACE."
    ALL_SUCCESS=false
    continue
  fi

  # Backup the PCAP file
  if [ -e $PCAP ]; then
    sudo cp $PCAP $BACKUP
  else
    log_info "No PCAP file found for $INTERFACE to backup."
    ALL_SUCCESS=false
  fi

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
      -E header=y \
      -E separator=, \
      -E quote=d \
      -E occurrence=f > "$CSV"; then
    log_info "Failed to convert PCAP to CSV for $INTERFACE."
    ALL_SUCCESS=false
  fi
done

if $ALL_SUCCESS; then
  log_info "Data collection, backup, and conversion to CSV completed."
else
  log_info "Some operations failed. Check the log for details."
fi

