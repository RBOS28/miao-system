#!/bin/bash

# Directory setup
BASE_DIR="$HOME/miao-system"
CAPTURE_DIR="$BASE_DIR/captures"
BACKUP_DIR="$BASE_DIR/backups"
LOG_FILE="$BASE_DIR/log.txt"

# Ensure directories exist
mkdir -p $CAPTURE_DIR $BACKUP_DIR

# Variables
PACKET_COUNT=10
PCAP_FILE="$CAPTURE_DIR/simple_test.pcap"
CSV_FILE="$CAPTURE_DIR/simple_test.csv"
BACKUP_PCAP="$BACKUP_DIR/simple_test_backup.pcap"

# Log function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

# Capture Packets
log "Starting packet capture..."
sudo tcpdump -i eth0 -c $PACKET_COUNT -w $PCAP_FILE

# Check if the capture was successful
if [[ ! -f $PCAP_FILE ]]; then
    log "Error: PCAP file not created."
    exit 1
fi

# Backup the PCAP
log "Backing up PCAP file..."
cp $PCAP_FILE $BACKUP_PCAP

# Convert PCAP to CSV
log "Converting PCAP to CSV..."
tshark -r $PCAP_FILE -T fields -e ip.src -e ip.dst -E header=y -E separator=, -E quote=d -E occurrence=f > $CSV_FILE

# Check if the CSV conversion was successful
if [[ ! -f $CSV_FILE ]]; then
    log "Error: CSV file not created."
    exit 1
fi

# Output to user
echo "Capture and conversion complete. Check the $BASE_DIR directory."
echo "For detailed logs, view $LOG_FILE."


