#!/bin/bash

# Enable debug mode
set -x

# Creating the directory and log file
LOG_DIR="$HOME/miao-system"
LOG_FILE="$LOG_DIR/diagnostic-log.log"
mkdir -p $LOG_DIR
touch $LOG_FILE
chmod -R 777 $LOG_DIR

# Outputting diagnostic info to the log file
echo "Diagnostic Log - $(date)" >> $LOG_FILE

# Manually capturing a small pcap
CAPTURE_FILE="$LOG_DIR/test.pcap"
sudo tcpdump -i eth0 -c 10 -w $CAPTURE_FILE >> $LOG_FILE 2>&1
echo "Tcpdump capture completed." >> $LOG_FILE

# Attempting to convert the pcap to CSV
CSV_FILE="$LOG_DIR/test.csv"
tshark -r $CAPTURE_FILE -T fields \
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
  -E occurrence=f > $CSV_FILE 2>> $LOG_FILE
echo "Tshark conversion attempted." >> $LOG_FILE

echo "Diagnostic script completed." >> $LOG_FILE

