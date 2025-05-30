#!/bin/bash
# Script: backup.sh
# Description: Creates compressed backups of directories and stores them in a specified location
# Author: Your Name
# Date: $(date +%F)

# --------------------------
# Initialize Logging
# --------------------------
LOG_FILE="/var/log/backup_script.log"
{
echo "=== Backup Script Started $(date) ==="

# --------------------------
# Input Handling
# --------------------------
if [ $# -eq 0 ]; then
    read -p "Enter directory to backup: " SOURCE_DIR
else
    SOURCE_DIR=$1
fi

# Validate source directory
if [ ! -d "$SOURCE_DIR" ]; then
    echo "ERROR: Directory does not exist: $SOURCE_DIR"
    exit 1
fi

# --------------------------
# Backup Destination
# --------------------------
read -p "Enter backup destination directory: " DEST_DIR

# Create destination if it doesn't exist
mkdir -p "$DEST_DIR" || {
    echo "ERROR: Failed to create destination directory"
    exit 2
}

# --------------------------
# Create Compressed Archive
# --------------------------
BACKUP_NAME="backup_$(basename "$SOURCE_DIR")_$(date +%Y%m%d_%H%M%S).tar.gz"

echo "Creating backup: $BACKUP_NAME"
tar -czf "$DEST_DIR/$BACKUP_NAME" "$SOURCE_DIR" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create backup archive"
    exit 3
fi

# --------------------------
# Verify Backup
# --------------------------
if [ -f "$DEST_DIR/$BACKUP_NAME" ]; then
    BACKUP_SIZE=$(du -h "$DEST_DIR/$BACKUP_NAME" | cut -f1)
    echo "SUCCESS: Backup created at $DEST_DIR/$BACKUP_NAME ($BACKUP_SIZE)"
else
    echo "ERROR: Backup file not found after creation"
    exit 4
fi

# --------------------------
# Completion
# --------------------------
echo "=== Backup Script Completed $(date) ==="
echo "Backup location: $DEST_DIR/$BACKUP_NAME"
} | tee -a "$LOG_FILE"

exit 0
