#!/bin/bash

set -e

# Function to check if a command exists
command_exists () {
  type "$1" &> /dev/null;
}

# Define directories and log file
LOG_DIR="$HOME/miao-system"
LOG_FILE="$LOG_DIR/log-file.log"
CAPTURE_DIR="/path/to/save/pcap_files"
CSV_DIR="/path/to/save/csv_files"
BACKUP_DIR="/path/to/save/backup_pcap_files"

# Create log directory and file with the correct permissions
sudo mkdir -p $LOG_DIR
sudo chown $USER:$USER $LOG_DIR
: > $LOG_FILE

# Log function for easy logging
log_info() {
  echo "$1" | tee -a $LOG_FILE
}

log_info "Starting script..."

# Check for required software and install if necessary
for pkg in tcpdump tshark; do
  if ! command_exists $pkg ; then
    log_info "$pkg not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y $pkg
  fi
done

# Update and Upgrade
log_info "Starting system update..."
if ! sudo apt-get update; then
  log_info "Failed to update packages."
  exit 1
fi
if ! sudo apt-get upgrade -y; then
  log_info "Failed to upgrade packages."
  exit 1
fi
log_info "System update complete."

# Create required directories with the correct permissions
for dir in $CAPTURE_DIR $CSV_DIR $BACKUP_DIR; do
  sudo mkdir -p $dir
  sudo chown $USER:$USER $dir
done

# List of interfaces to capture on
INTERFACES=("eth0" "wlan0")

# Packet capture parameters
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
  cp $PCAP $BACKUP
  
  # Convert the PCAP to CSV format
  if ! tshark -r "$PCAP" -T fields \
    -e ip.src \
    -e ip.dst \
    -E header=y \
    -E separator=, \
    -E quote=d \
    -E occurrence=f \
    > "$CSV"; then
      log_info "Failed to convert PCAP to CSV for $INTERFACE."
      ALL_SUCCESS=false
  fi
done

if $ALL_SUCCESS; then
  log_info "All operations completed successfully."
else
  log_info "Some operations failed. Check the log for details."
fi

