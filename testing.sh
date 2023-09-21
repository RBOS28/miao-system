#!/bin/bash

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
echo "Log directory and file should now be created." | tee -a $LOG_FILE

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
sudo apt-get update
sudo apt-get upgrade -y
echo "System update complete." | tee -a $LOG_FILE

# Directory to save the capture and backup files
CAPTURE_DIR="/$HOME/miao-system/capture-pcap"
CSV_DIR="/$HOME/miao-system/capture-csv"
BACKUP_DIR="/$HOME/miao-system/backup-pcap"

# Make sure the directories exist
mkdir -p $CAPTURE_DIR
mkdir -p $CSV_DIR
mkdir -p $BACKUP_DIR

# List of interfaces to capture on
INTERFACES=("eth0" "wlan0")

# Packet capture parameters
PACKET_COUNT=1000

for INTERFACE in "${INTERFACES[@]}"; do
  # File name
  PCAP="$CAPTURE_DIR/${INTERFACE}_traffic.pcap"
  CSV="$CSV_DIR/${INTERFACE}_traffic.csv"
  BACKUP="$BACKUP_DIR/${INTERFACE}_traffic_backup.pcap"

  # Capture packets
  sudo tcpdump -i $INTERFACE -c $PACKET_COUNT -w "$PCAP"

  # Backup the PCAP file
  cp $PCAP $BACKUP

  # Convert the PCAP to a simplified CSV format
  tshark -r "$PCAP" -T fields -e ip.src -e ip.dst -E header=y -E separator=, > "$CSV"
done

echo "Data collection and conversion to CSV completed." | tee -a $LOG_FILE

