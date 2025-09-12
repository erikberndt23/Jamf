#!/bin/bash
#
# Uninstall Heimdal Thor Agent
#

# Variables
SCRIPT_URL="https://prodcdn.heimdalsecurity.com/resources/uninstallHeimdalAgent.sh"
SCRIPT_NAME="uninstallHeimdalAgent.sh"
TMP_DIR="/private/tmp"
SCRIPT_PATH="$TMP_DIR/$SCRIPT_NAME"

echo "Heimdal Thor Agent Uninstall - Starting"

# Download uninstall script
echo "Downloading uninstall script from $SCRIPT_URL ..."
curl -s -L "$SCRIPT_URL" -o "$SCRIPT_PATH"

# Check if the download succeeded
if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo "Error: Failed to download uninstall script."
    exit 1
fi

# Make the script executable
chmod +x "$SCRIPT_PATH"

# Run the uninstall script
echo "Running Heimdal uninstall script..."
sudo "$SCRIPT_PATH"
UNINSTALL_EXIT_CODE=$?

# Cleanup
echo "Cleaning up..."
rm -f "$SCRIPT_PATH"

# Exit code handling for Jamf
if [[ $UNINSTALL_EXIT_CODE -eq 0 ]]; then
    echo "Heimdal Thor Agent Uninstall - Completed Successfully"
    exit 0
else
    echo "Heimdal Thor Agent Uninstall - Failed with exit code $UNINSTALL_EXIT_CODE"
    exit $UNINSTALL_EXIT_CODE
fi
