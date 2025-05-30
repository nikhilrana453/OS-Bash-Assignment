#!/bin/bash
# Script: user_setup.sh
# Description: Automates user creation and environment setup from a CSV file in Docker
# Author: Your Name
# Date: $(date +%F)

# --------------------------
# Initialize Logging
# --------------------------
LOG_FILE="/var/log/user_script.log"
{
echo "=== User Setup Script Started $(date) ==="
echo "Script executed with arguments: $@"

# --------------------------
# Validate Input
# --------------------------
if [ $# -eq 0 ]; then
    echo "ERROR: No CSV file provided. Usage: $0 <users.csv>"
    echo "Alternatively provide a URL to download the CSV file."
    exit 1
fi

CSV_SOURCE=$1

# --------------------------
# Handle Local/Remote CSV
# --------------------------
if [[ $CSV_SOURCE == http* ]]; then
    echo "INFO: Downloading remote CSV file..."
    CSV_FILE="/tmp/users_$(date +%s).csv"
    
    # Try wget first, then curl
    if command -v wget &> /dev/null; then
        wget -q -O "$CSV_FILE" "$CSV_SOURCE" || {
            echo "ERROR: Failed to download CSV with wget"
            exit 2
        }
    elif command -v curl &> /dev/null; then
        curl -s -o "$CSV_FILE" "$CSV_SOURCE" || {
            echo "ERROR: Failed to download CSV with curl"
            exit 2
        }
    else
        echo "ERROR: Neither wget nor curl available to download remote file"
        exit 3
    fi
else
    CSV_FILE="$CSV_SOURCE"
fi

# Verify CSV exists and is readable
if [ ! -f "$CSV_FILE" ]; then
    echo "ERROR: CSV file not found: $CSV_FILE"
    exit 4
fi

if [ ! -r "$CSV_FILE" ]; then
    echo "ERROR: Cannot read CSV file: $CSV_FILE"
    exit 5
fi

# --------------------------
# Check Required Commands
# --------------------------
REQUIRED_COMMANDS=("useradd" "groupadd" "chpasswd" "getent" "usermod")
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "ERROR: Required command not found: $cmd"
        exit 6
    fi
done

# --------------------------
# Process CSV File
# --------------------------
echo "INFO: Processing CSV file: $CSV_FILE"
echo "Header from CSV:"
head -n 1 "$CSV_FILE"

# Count total lines (for progress)
TOTAL_USERS=$(tail -n +2 "$CSV_FILE" | wc -l)
CURRENT_USER=0

tail -n +2 "$CSV_FILE" | while IFS=, read -r email birthdate groups sharedFolder; do
    ((CURRENT_USER++))
    
    # --------------------------
    # Validate Fields
    # --------------------------
    if [ -z "$email" ] || [ -z "$birthdate" ]; then
        echo "WARNING: Skipping row $CURRENT_USER - missing email or birthdate"
        continue
    fi

    # --------------------------
    # Extract Username
    # --------------------------
    username=$(echo "$email" | cut -d '@' -f1 | tr '[:upper:]' '[:lower:]' | tr '.' '_')
    
    # Validate username format
    if [[ ! "$username" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        echo "WARNING: Invalid username format for $email - skipping"
        continue
    fi

    # --------------------------
    # Generate Password
    # --------------------------
    if ! password=$(date -d "$birthdate" +"%m%Y" 2>/dev/null); then
        echo "WARNING: Invalid birthdate format for $email (expected YYYY-MM-DD) - using default password"
        password="Welcome123"
    fi

    # --------------------------
    # Create User
    # --------------------------
    if ! id "$username" &>/dev/null; then
        echo "PROGRESS: [$CURRENT_USER/$TOTAL_USERS] Creating user: $username"
        
        if ! useradd -m -s /bin/bash "$username"; then
            echo "ERROR: Failed to create user $username"
            continue
        fi
        
        # Set password
        if ! echo "$username:$password" | chpasswd; then
            echo "ERROR: Failed to set password for $username"
        else
            echo "INFO: Password set for $username"
            
            # Force password change on first login
            chage -d 0 "$username"
        fi
    else
        echo "INFO: User $username already exists - skipping creation"
    fi

    # --------------------------
    # Process Groups
    # --------------------------
    cleaned_groups=$(echo "$groups" | tr -d '"' | tr ',' '\n')
    
    echo "$cleaned_groups" | while read -r group; do
        if [ -n "$group" ]; then
            # Create group if not exists
            if ! getent group "$group" &>/dev/null; then
                if ! groupadd "$group"; then
                    echo "ERROR: Failed to create group $group"
                    continue
                fi
                echo "INFO: Created group: $group"
            fi

            # Add user to group
            if ! usermod -aG "$group" "$username"; then
                echo "ERROR: Failed to add $username to group $group"
            else
                echo "INFO: Added $username to group $group"
            fi
        fi
    done

    # --------------------------
    # Setup Shared Folder
    # --------------------------
    if [ -n "$sharedFolder" ]; then
        # Use first group for permissions if available
        primary_group=$(echo "$cleaned_groups" | head -n 1)
        if [ -z "$primary_group" ]; then
            primary_group="$username"
        fi

        # Create shared folder
        if [ ! -d "$sharedFolder" ]; then
            if ! mkdir -p "$sharedFolder"; then
                echo "ERROR: Failed to create shared folder $sharedFolder"
                continue
            fi
            echo "INFO: Created shared folder: $sharedFolder"
        fi

        # Set permissions
        if ! chown :"$primary_group" "$sharedFolder"; then
            echo "ERROR: Failed to set group ownership for $sharedFolder"
        fi

        if ! chmod 770 "$sharedFolder"; then
            echo "ERROR: Failed to set permissions for $sharedFolder"
        fi

        # Create symlink
        symlink_path="/home/$username/shared"
        if [ -L "$symlink_path" ]; then
            rm "$symlink_path"
        fi

        if ! ln -s "$sharedFolder" "$symlink_path"; then
            echo "ERROR: Failed to create symlink for $sharedFolder"
        else
            echo "INFO: Created symlink $symlink_path -> $sharedFolder"
            
            # Set correct ownership of symlink
            chown "$username":"$username" "$symlink_path"
        fi
    fi

    # --------------------------
    # Final User Report
    # --------------------------
    echo "SUCCESS: Completed setup for $username"
    echo "----- User Details -----"
    echo "Username: $username"
    echo "Home Dir: /home/$username"
    echo "Groups: $(groups $username)"
    echo "Password: $password"
    if [ -n "$sharedFolder" ]; then
        echo "Shared Folder: $sharedFolder"
        echo "Symlink: /home/$username/shared"
    fi
    echo "------------------------"
done

# --------------------------
# Script Completion
# --------------------------
echo "=== User Setup Script Completed $(date) ==="
echo "Summary:"
echo "Total users processed: $TOTAL_USERS"
echo "Log file available at: $LOG_FILE"
} | tee -a "$LOG_FILE"

exit 0
