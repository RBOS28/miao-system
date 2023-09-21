#!/bin/bash

LOG_DIR="$HOME/miao-system"
LOG_FILE="$LOG_DIR/test-log.log"

mkdir -p $LOG_DIR

echo "This is a test log entry" > $LOG_FILE

echo "Log test completed."

