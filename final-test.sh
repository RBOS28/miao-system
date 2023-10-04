#!/bin/bash

# Define directories and files
BASE_DIR="$HOME/miao-system"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/system-log.log"
CAPTURE_DIR="$BASE_DIR/pcap_files"
CSV_DIR="$BASE_DIR/csv_files"
BACKUP_DIR="$BASE_DIR/backup_pcap_files"
INTERFACES=("eth0" "wlan0")
PACKET_COUNT=1000

# Logging functions
log_info() {
    echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S'): $1" | sudo tee -a $LOG_FILE
}

log_error() {
    echo "[ERROR] $(date +'%Y-%m-%d %H:%M:%S'): $1" | sudo tee -a $LOG_FILE
}

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    log_error "Please run this script as root or with sudo."
    exit 1
fi

# Exit on any error
set -e

# Check if commands exist
command_exists () {
    type "$1" &> /dev/null
}

# Create necessary directories
sudo mkdir -p $LOG_DIR $CAPTURE_DIR $CSV_DIR $BACKUP_DIR
sudo chmod 777 $LOG_DIR $CAPTURE_DIR $CSV_DIR $BACKUP_DIR

# Truncate the log file
: > $LOG_FILE

log_info "Starting comprehensive system script..."

# Update system and install necessary packages
log_info "Updating system and installing necessary packages..."
sudo apt-get update
sudo apt-get upgrade -y
for cmd in tcpdump tshark; do
    if ! command_exists $cmd; then
        log_info "$cmd not found. Installing..."
        sudo apt-get install -y $cmd
    else
        log_info "$cmd already installed."
    fi
done

log_info "System update and package installation completed."

# Iterate over each interface and perform packet capture and conversion
log_info "Starting packet capture and conversion..."
for INTERFACE in "${INTERFACES[@]}"; do
    PCAP="$CAPTURE_DIR/${INTERFACE}_traffic.pcap"
    CSV="$CSV_DIR/${INTERFACE}_traffic.csv"
    BACKUP="$BACKUP_DIR/${INTERFACE}_traffic_backup.pcap"
    
    # Check if interface exists
    if ! ip link show $INTERFACE > /dev/null 2>&1; then
        log_error "Interface $INTERFACE not found."
        continue
    fi
    
    # Capture packets using tcpdump
    log_info "Capturing packets on $INTERFACE..."
    sudo tcpdump -i $INTERFACE -c $PACKET_COUNT -w "$PCAP"
    
    # Check if PCAP file is created
    if [ ! -f "$PCAP" ]; then
        log_error "PCAP file not created for $INTERFACE."
        continue
    fi
    
    # Backup the PCAP file
    log_info "Backing up PCAP for $INTERFACE..."
    sudo cp $PCAP $BACKUP
    
    # Convert PCAP to CSV format using tshark
    log_info "Converting PCAP to CSV for $INTERFACE..."
    sudo tshark -r "$PCAP" -T fields -e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport -e udp.srcport -e udp.dstport -e frame.time_epoch -e _ws.col.Protocol -e frame.len -E header=y -E separator=, -E quote=d -E occurrence=f > "$CSV"
    
    # Check if CSV file is created
    if [ ! -f "$CSV" ]; then
        log_error "CSV file not created for $INTERFACE."
        continue
    fi
    
    log_info "Packet capture and conversion for $INTERFACE completed successfully."
done

log_info "Comprehensive system script execution completed."




