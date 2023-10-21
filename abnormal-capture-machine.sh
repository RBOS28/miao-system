#!/bin/bash

# Determine the home directory
if [[ $EUID -eq 0 ]]; then
  HOME_DIR="/root"
  if [ ! -z "$SUDO_USER" ]; then
    HOME_DIR=$(eval echo ~$SUDO_USER)
  fi
else
  HOME_DIR="$HOME"
fi

# Define log file
LOG_DIR="$HOME_DIR/miao-system/abnormal-traffic/"
LOG_FILE="$LOG_DIR/log-file.log"

# Logging functions
log_info() {
    echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S'): $1" | tee -a $LOG_FILE
}

log_error() {
    echo "[ERROR] $(date +'%Y-%m-%d %H:%M:%S'): $1" | tee -a $LOG_FILE
}

# Check for root user
if [[ $EUID -ne 0 ]]; then
    log_error "Please run this script as root or with sudo."
    exit 1
fi

# Function to check if a command exists
command_exists () {
  type "$1" &> /dev/null
}

# Create log directory if it doesn't exist
mkdir -p $LOG_DIR
chmod 755 $LOG_DIR

# Create or truncate the log file
: > $LOG_FILE

# Check if tcpdump is installed, if not install it
if ! command_exists tcpdump ; then
  log_info "tcpdump not found. Installing..."
  apt-get update
  apt-get install -y tcpdump
fi

# Check if tshark is installed, if not install it
if ! command_exists tshark ; then
  log_info "tshark not found. Installing..."
  apt-get update
  apt-get install -y tshark
fi

log_info "Starting to update system..."
apt-get update
apt-get upgrade -y
log_info "System update complete."

# Directories to save the capture and backup files
CAPTURE_DIR="$HOME_DIR/miao-system/abnormal-traffic/pcap_files"
CSV_DIR="$HOME_DIR/miao-system/abnormal-traffic/csv_files"
BACKUP_DIR="$HOME_DIR/miao-system/abnormal-traffic/backup_pcap_files"

# Make sure the directories exist
mkdir -p $CAPTURE_DIR $CSV_DIR $BACKUP_DIR
chmod 755 $CAPTURE_DIR $CSV_DIR $BACKUP_DIR

# List of interfaces to capture on
INTERFACES=("eth0" "wlan0")

# Packet capture parameters
PACKET_COUNT=1000

ALL_SUCCESS=true

log_info "Cleaning up old files"
rm -rf $CAPTURE_DIR/* $CSV_DIR/* $BACKUP_DIR/*

for INTERFACE in "${INTERFACES[@]}"; do
  PCAP="$CAPTURE_DIR/${INTERFACE}_traffic.pcap"
  CSV="$CSV_DIR/${INTERFACE}_traffic.csv"
  BACKUP="$BACKUP_DIR/${INTERFACE}_traffic_backup.pcap"

  if ! ip link show $INTERFACE > /dev/null 2>&1; then
    log_error "Interface $INTERFACE not found."
    ALL_SUCCESS=false
    continue
  fi

  # Capture packets
  if ! tcpdump -i $INTERFACE -c $PACKET_COUNT -w "$PCAP"; then
    log_error "Failed to capture packets on $INTERFACE."
    ALL_SUCCESS=false
    continue
  fi

  # Backup the PCAP file
  cp $PCAP $BACKUP

  # Convert the PCAP to CSV format
  if ! tshark -r "$PCAP" -T fields \
    -e ip.src \
    -e ip.dst \
	-e ip.ttl \
    -e tcp.srcport \
    -e tcp.dstport \
	-e tcp.flags \
    -e tcp.seq \
    -e tcp.ack \
    -e udp.srcport \
    -e udp.dstport \
    -e frame.time_epoch \
    -e _ws.col.Protocol \
    -e frame.len \
	-e data.data \
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
done

if [ "$ALL_SUCCESS" = true ]; then
  log_info "Data collection, backup, and conversion to CSV completed."
else
  log_error "Some operations failed. Check the log for details."
fi

