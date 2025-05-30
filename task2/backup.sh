#!/bin/bash
# Script: backup.sh
# Description: Creates compressed backups of directories and stores them in a specified location.
#              Also includes functionality to extract existing backups.
# Author: Nikhil
# Student ID: 1000122193
# Date: $(date +%F)

# --------------------------
# Initialize Logging
# --------------------------
LOG_FILE="/var/log/backup_script.log"
{
echo "=== Backup Script Started $(date) ==="

# --------------------------
# Main Menu
# --------------------------
echo "Select operation:"
echo "1) Create backup"
echo "2) Extract backup"
read -p "Enter choice (1 or 2): " OPERATION

case $OPERATION in
    1)
        # --------------------------
        # Backup Creation
        # --------------------------
        # Input Handling
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

        # Backup Destination
        read -p "Enter backup destination directory: " DEST_DIR

        # Create destination if it doesn't exist
        mkdir -p "$DEST_DIR" || {
            echo "ERROR: Failed to create destination directory"
            exit 2
        }

        # Create Compressed Archive
        BACKUP_NAME="backup_$(basename "$SOURCE_DIR")_$(date +%Y%m%d_%H%M%S).tar.gz"

        echo "Creating backup: $BACKUP_NAME"
        tar -czf "$DEST_DIR/$BACKUP_NAME" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" 2>/dev/null

        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to create backup archive"
            exit 3
        fi

        # Verify Backup
        if [ -f "$DEST_DIR/$BACKUP_NAME" ]; then
            BACKUP_SIZE=$(du -h "$DEST_DIR/$BACKUP_NAME" | cut -f1)
            echo "SUCCESS: Backup created at $DEST_DIR/$BACKUP_NAME ($BACKUP_SIZE)"
        else
            echo "ERROR: Backup file not found after creation"
            exit 4
        fi
        ;;

    2)
        # --------------------------
        # Backup Extraction
        # --------------------------
        read -p "Enter backup file to extract: " BACKUP_FILE
        if [ ! -f "$BACKUP_FILE" ]; then
            echo "ERROR: Backup file does not exist: $BACKUP_FILE"
            exit 5
        fi

        read -p "Enter extraction target directory: " TARGET_DIR
        mkdir -p "$TARGET_DIR" || {
            echo "ERROR: Failed to create target directory"
            exit 6
        }

        echo "Extracting $BACKUP_FILE to $TARGET_DIR"
        tar -xzf "$BACKUP_FILE" -C "$TARGET_DIR" 2>/dev/null

        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to extract backup archive"
            exit 7
        fi

        echo "SUCCESS: Backup extracted to $TARGET_DIR"
        ;;

    *)
        echo "ERROR: Invalid operation selected"
        exit 8
        ;;
esac

# --------------------------
# Completion
# --------------------------
echo "=== Backup Script Completed $(date) ==="
} | tee -a "$LOG_FILE"

exit 0