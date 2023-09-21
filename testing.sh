#!/bin/bash

# Function to check if a command exists
command_exists () {
  type "$1" &> /dev/null;
}

# Define log directory and file
LOG_DIR="$HOME/miao-system"
LOG_FILE="$LOG_DIR/log-file.log"

# Ensure we have correct permissions for log directory
if [ ! -d "$LOG_DIR" ]; then
    sudo mkdir -p $LOG_DIR
    sudo chmod 755 $LOG_DIR
fi

# Initialize or truncate the log file
sudo : > $LOG_FILE

# Add debugging information to log file
echo "About to create log directory and file..." | sudo tee -a $LOG_FILE
echo "Log directory and file should now be created." | sudo tee -a $LOG_FILE

# Check and install tcpdump if not available
if ! command_exists tcpdump ; then
    echo "tcpdump not found. Installing..." | sudo tee -a $LOG_FILE
    sudo apt-get update
    sudo apt-get install -y tcpdump
fi

# Check and install tshark if not available
if ! command_exists tshark ; then
    echo "tshark not found. Installing..." | sudo tee -a $LOG_FILE
    sudo apt-get update
    sudo apt-get install -y tshark
fi

# System update and upgrade
echo "Starting to update system..." | sudo tee -a $LOG_FILE
sudo apt-get update && sudo apt-get upgrade -y
echo "System update complete." | sudo tee -a $LOG_FILE

# Define directories for pcap, csv, and backup
CAPTURE_DIR="/path/to/save/pcap_files"
CSV_DIR="/path/to/save/csv_files"
BACKUP_DIR="/path/to/save/backup_pcap_files"

# Ensure directories exist
sudo mkdir -p $CAPTURE_DIR
sudo mkdir -p $CSV_DIR
sudo mkdir -p $BACKUP_DIR

# List of interfaces to capture on
INTERFACES=("eth0" "wlan0")

# Packet capture parameters
PACKET_COUNT=1000

# Flag to monitor success of operations
ALL_SUCCESS=true

for INTERFACE in "${INTERFACES[@]}"; do
    PCAP="$CAPTURE_DIR/${INTERFACE}_traffic.pcap"
    CSV="$CSV_DIR/${INTERFACE}_traffic.csv"
    BACKUP="$BACKUP_DIR/${INTERFACE}_traffic_backup.pcap"

    # Capture packets
    sudo tcpdump -i $INTERFACE -c $PACKET_COUNT -w "$PCAP"

    # Backup the PCAP file
    sudo cp $PCAP $BACKUP

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
            echo "Failed to convert PCAP to CSV for $INTERFACE." | sudo tee -a $LOG_FILE
            ALL_SUCCESS=false
    fi
done

if [ "$ALL_SUCCESS" = true ]; then
    echo "Data collection and conversion to CSV completed." | sudo tee -a $LOG_FILE
else
    echo "Some operations failed. Check the log for details." | sudo tee -a $LOG_FILE
fi

