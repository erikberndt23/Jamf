#!/bin/zsh
# This will import the ASTi Forticlient VPN configuration

ZIP_FILE="/Library/Application Support/JAMF/Waiting Room/ASTI_VPN_SSO_Mac.zip"
DEST_DIR="/Library/Application Support/JAMF/Waiting Room/"
CONF_FILE="$DEST_DIR/ASTI_VPN_SSO_Mac.conf"
FCCONFIG="/Library/Application Support/Fortinet/FortiClient/bin/fcconfig"

# Unzip the config file
unzip -o "$ZIP_FILE" -d "$DEST_DIR"

#Check if unzip was successful
if [[ $? -eq 0 ]]; then
    echo "Unzip completed successfully"
else
    echo "Unzip failed"
    exit 1
fi

# Check if VPN config file exists
if [[ ! -f "$CONF_FILE" ]]; then
    echo "VPN config file not found at $CONF_FILE"
    exit 1
fi

# Check if Forticlient CLI exists
if [[ ! -x "$FCCONFIG" ]]; then
    echo "FortiClient CLI not found or not executable at $FCCONFIG"
    exit 1
fi

# Import the VPN config
echo "Importing VPN configuration..."
"$FCCONFIG" -m vpn -f "$CONF_FILE" -o import

if [[ $? -eq 0 ]]; then
    echo "VPN configuration imported successfully."
else
    echo "Failed to import VPN configuration."
    exit 1
fi