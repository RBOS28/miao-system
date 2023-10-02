#!/bin/bash

# Define log file
LOG_DIR="$HOME/miao-system"
LOG_FILE="$LOG_DIR/log-file.log"

# Logging functions
log_info() {
  echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S'): $1" | sudo tee -a $LOG_FILE
}

log_error() {
  echo "[ERROR] $(date +'%Y-%m-%d %H:%M:%S'): $1" | sudo tee -a $LOG_FILE
}

if [[ $EUID -ne 0 ]]; then
  log_error "Please run this script as root or with sudo."
  exit 1
fi

# Exit on any error
set -e

# Function to check if a command exists
command_exists () {
  which "$1" &> /dev/null
}

# Create log directory if it doesn't exist
sudo mkdir -p $LOG_DIR
sudo chmod 777 $LOG_DIR

# Create or truncate the log file
: > $LOG_FILE

log_info "Checking for required utilities..."

# Check if tcpdump is installed, if not install it
if ! command_exists tcpdump ; then
  log_info "tcpdump not found. Installing..."
  sudo apt-get update
  sudo apt-get install -y tcpdump
else
  log_info "tcpdump already installed."
fi

# Check if tshark is installed, if not install it
if ! command_exists tshark ; then
  log_info "tshark not found. Installing..."
  sudo apt-get update
  sudo apt-get install -y tshark
else
  log_info "tshark already installed."
fi

log_info "Starting system update..."
sudo apt-get update
sudo apt-get upgrade -y
log_info "System update complete."

# Directory to save the capture and backup files
CAPTURE_DIR="$HOME/miao-system/pcap_files"
CSV_DIR="$HOME/miao-system/csv_files"
BACKUP_DIR="$HOME/miao-system/backup_pcap_files"

# Make sure the directories exist
sudo mkdir -p $CAPTURE_DIR $CSV_DIR $BACKUP_DIR
sudo chmod 777 $CAPTURE_DIR $CSV_DIR $BACKUP_DIR

# List of interfaces to capture on
INTERFACES=("eth0" "wlan0")

# Packet capture parameters
PACKET_COUNT=1000

ALL_SUCCESS=true

log_info "Cleaning up old files."
sudo rm -rf $CAPTURE_DIR/* $CSV_DIR/* <span class="math-inline">BACKUP\_DIR/\*
\# Before trying to create PCAP and CSV files
AVAILABLE\_SPACE\=</span>(df --output=avail "$CAPTURE_DIR" | tail -n 1)
if [ $AVAILABLE_SPACE -lt 1000000 ]; then # Adjust the space threshold as needed
  log_error "Not enough disk space available in <span class="math-inline">CAPTURE\_DIR\."
ALL\_SUCCESS\=false
continue
fi
for INTERFACE in "</span>{INTERFACES[@]}"; do
  PCAP="<span class="math-inline">CAPTURE\_DIR/</span>{INTERFACE}_traffic.pcap"
  CSV="<span class="math-inline">CSV\_DIR/</span>{INTERFACE}_traffic.csv"
  BACKUP="<span class="math-inline">BACKUP\_DIR/</span>{INTERFACE}_traffic_backup.pcap"

  if ! ip link show $INTERFACE > /dev/null 2>&1; then
    log_error "Interface $INTERFACE not found."
    continue
  fi

	# Before running tcpdump
	if ! ip link show $INTERFACE | grep -q "UP"; then
  	log_error "Interface $INTERFACE is down. Please ensure the interface is up and has traffic flowing through it."
  	ALL_SUCCESS=false
  	continue
	fi

	# Capture packets
  log_info "Starting packet capture on $INTERFACE..."
  if ! sudo tcpdump -i $INTERFACE -c $PACKET_COUNT -w "$PCAP"; then
    log_error "Failed to capture packets on $INTERFACE. Error: $?"
    ALL_SUCCESS=false
    continue
  fi

	# After tcpdump
	 if [ ! -f "$PCAP" ]; then
    log_error "PCAP file not created for $INTERFACE."
    ALL_SUCCESS=false
    continue
  fi

  # Backup the PCAP file
  log_info "Backing up pcap for $INTERFACE..."
  if ! sudo cp $PCAP $BACKUP 2>> $LOG_FILE; then
