#!/bin/bash

# Define directories and filenames
BASE_DIR="$HOME/miao-system"
PCAP_FILE="$BASE_DIR/captured_traffic.pcap"
CSV_FILE="$BASE_DIR/captured_traffic.csv"
BACKUP_PCAP="$BASE_DIR/backup_traffic.pcap"

# Ensure the directory exists
mkdir -p $BASE_DIR

# Capture packets using tcpdump
sudo tcpdump -i eth0 -c 1000 -w $PCAP_FILE

# Backup the PCAP file
cp $PCAP_FILE $BACKUP_PCAP

# Convert the .pcap file to .csv using tshark
sudo tshark -r $PCAP_FILE -T fields \
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
    -E occurrence=f > $CSV_FILE

echo "Files saved to $BASE_DIR


