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
  type "$1" &> /dev/null
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
sudo rm -rf $CAPTURE_DIR/* $CSV_DIR/* $BACKUP_DIR/*

for INTERFACE in "${INTERFACES[@]}"; do
    PCAP="$CAPTURE_DIR/${INTERFACE}_traffic.pcap"
    CSV="$CSV_DIR/${INTERFACE}_traffic.csv"
    BACKUP="$BACKUP_DIR/${INTERFACE}_traffic_backup.pcap"

    if ! ip link show $INTERFACE > /dev/null 2>&1; then
        log_error "Interface $INTERFACE not found."
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
    	log_error "Failed to backup PCAP for $INTERFACE."
    	ALL_SUCCESS=false
	fi

    # Convert the PCAP to CSV format
    log_info "Starting pcap to csv conversion for $INTERFACE..."
    if ! sudo tshark -r "$PCAP" -T fields \
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
        -e frame.cap_len \
        -E header=y \
        -E separator=, \
        -E quote=d \
        -E occurrence=f > "$CSV"; then
        log_error "Failed to convert PCAP to CSV for $INTERFACE."
        ALL_SUCCESS=false
    fi

	 # After tshark
    if [ ! -f "$CSV" ]; then
        log_error "CSV file not created for $INTERFACE."
        ALL_SUCCESS=false
    fi
done

if [ "$ALL_SUCCESS" = true ]; then
    log_info "Data collection, backup, and conversion to CSV completed."
else
    log_info "Some operations failed. Check the log for details."
fi

