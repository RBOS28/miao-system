#!/bin/bash

# Exit on any error
set -e

# Log creation function
log() {
    local message="$1"
    echo "$message" | tee -a "$LOG_FILE"
}

# Function to check if a command exists
command_exists () {
    which "$1" &> /dev/null;
}

# Define log file
LOG_DIR="$HOME/miao-system"
LOG_FILE="$LOG_DIR/log-file.log"

# Create log directory if it doesn't exist
mkdir -p $LOG_DIR

# Create or truncate the log file
: > $LOG_FILE

log "Script started."

log "About to create log directory and file..."

# Check if tcpdump is installed, if not install it
log "Before checking tcpdump..."
if ! command_exists tcpdump ; then
    log "tcpdump not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y tcpdump
fi

# Check if tshark is installed, if not install it
log "Before checking tshark..."
if ! command_exists tshark ; then
    log "tshark not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y tshark
fi

# Update and Upgrade
log "Starting to update system..."
if ! sudo apt-get update; then
    log "Failed to update packages"
    exit 1
fi
if ! sudo apt-get upgrade -y; then
    log "Failed to upgrade packages"
    exit 1
fi
log "System update complete."

# Directory to save the capture and backup files
CAPTURE_DIR="/$HOME/miao-system/pcap_files"
CSV_DIR="/$HOME/miao-system/csv_files"
BACKUP_DIR="/$HOME/miao-system/backup_pcap_files"

# Make sure the directories exist
log "Creating capture, csv, and backup directories..."
mkdir -p $CAPTURE_DIR
mkdir -p $CSV_DIR
mkdir -p $BACKUP_DIR

# List of interfaces to capture on
INTERFACES=("eth0" "wlan0")

# Packet capture parameters
PACKET_COUNT=1000

ALL_SUCCESS=true

for INTERFACE in "${INTERFACES[@]}"; do
    # File name
    PCAP="$CAPTURE_DIR/${INTERFACE}_traffic.pcap"
    CSV="$CSV_DIR/${INTERFACE}_traffic.csv"
    BACKUP="$BACKUP_DIR/${INTERFACE}_traffic_backup.pcap"

    # Capture packets
    log "Capturing packets on $INTERFACE..."
    if ! sudo tcpdump -i $INTERFACE -c $PACKET_COUNT -w "$PCAP"; then
        log "Failed to capture packets on $INTERFACE."
        continue
    fi

    # Backup the PCAP file
    log "Backing up the pcap file for $INTERFACE..."
    cp $PCAP $BACKUP

    # Convert the PCAP to CSV format
    log "Converting pcap to csv for $INTERFACE..."
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
        log "Failed to convert PCAP to CSV for $INTERFACE."
        ALL_SUCCESS=false
    fi
done

if [ "$ALL_SUCCESS" = true ]; then
    log "Data collection, backup, and conversion to CSV completed."
else
    log "Some operations failed. Check the log for details."
fi

