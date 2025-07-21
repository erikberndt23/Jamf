#!/bin/bash

# Bitwarden Installer Script for Jamf Pro

# Download Variables
BW_URL="https://bitwarden.com/download/?app=desktop&platform=macos&variant=dmg"
BW_DMG="/tmp/Bitwarden.dmg"
MOUNT_POINT=$(mktemp -d /Volumes/BitwardenMount.XXXX)

echo "Downloading Bitwarden..."
if ! curl -L -o "$BW_DMG" "$BW_URL"; then
    echo "ERROR: Failed to download Bitwarden."
    exit 1
fi

# Mount the Bitwarden DMG
echo "Mounting DMG..."
if ! hdiutil attach "$BW_DMG" -mountpoint "$MOUNT_POINT" -nobrowse -quiet; then
    echo "ERROR: Failed to mount DMG."
    rm -f "$BW_DMG"
    exit 1
fi

# Check if Bitwarden is already installed
if [ -d "/Applications/Bitwarden.app" ]; then
    echo "Bitwarden already installed. Skipping copy."
else
    if [ -d "$MOUNT_POINT/Bitwarden.app" ]; then
        echo "Installing Bitwarden..."
        cp -R "$MOUNT_POINT/Bitwarden.app" /Applications/
    else
        echo "ERROR: Bitwarden.app not found in DMG."
        hdiutil detach "$MOUNT_POINT" -quiet
        rm -f "$BW_DMG"
        exit 1
    fi
fi

# Unmount Bitwarden DMG
echo "Unmounting DMG..."
hdiutil detach "$MOUNT_POINT" -quiet

# Cleanup installation files
echo "Cleaning up..."
rm -f "$BW_DMG"
rmdir "$MOUNT_POINT"
echo "Bitwarden installation complete."
exit 0