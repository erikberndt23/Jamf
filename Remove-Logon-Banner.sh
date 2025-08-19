#!/bin/bash
# Path to the PolicyBanner file
BANNER_FILE="/Library/Security/PolicyBanner.rtf"

# Check if the file exists

echo "Checking for PolicyBanner at $BANNER_FILE..."
if [ -f "$BANNER_FILE" ]; then
    echo "PolicyBanner found at $BANNER_FILE. Deleting..."
    rm -f "$BANNER_FILE"

    # Verify deletion
    if [ ! -f "$BANNER_FILE" ]; then
        echo "PolicyBanner successfully deleted."
        exit 0
    else
        echo "Failed to delete PolicyBanner."
        exit 1
    fi
else
    echo "No PolicyBanner found at $BANNER_FILE."
    exit 0
fi
