#!/bin/bash

# SMB server and share name
SERVER="swampthing.asti-usa.com"
SHARE="Marketing"
MOUNT_POINT="/Volumes/$SHARE"

# Logged-in user
CURRENT_USER=$(stat -f "%Su" /dev/console)

# Keychain search
PASS=$(/usr/bin/security find-internet-password -s "$SERVER" -a "$CURRENT_USER" -w 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "No credentials found in Keychain for $SERVER"

    exit 0
    echo "Credentials already stored in Keychain"
    # Use saved username
    USERNAME=$(security find-internet-password -s "$SERVER" -l "$SHARE" -w -g 2>&1 | grep "acct" | cut -d\" -f2)
fi

# Ensure mount point exists
[ ! -d "$MOUNT_POINT" ] && mkdir -p "$MOUNT_POINT"

# Unmount if already mounted
if mount | grep -q "$MOUNT_POINT"; then
    umount "$MOUNT_POINT"
fi

# Try mounting
echo "Mounting //$USERNAME@$SERVER/$SHARE"
sudo -u "$CURRENT_USER" /sbin/mount_smbfs "//$USERNAME@$SERVER/$SHARE" "$MOUNT_POINT"

if [ $? -eq 0 ]; then
    echo "SMB share mounted successfully at $MOUNT_POINT"
else
    echo "Failed to mount SMB share. Check username format or credentials."
fi