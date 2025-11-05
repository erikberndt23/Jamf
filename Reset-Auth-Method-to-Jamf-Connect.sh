#!/bin/bash

AUTHCHANGER="/usr/local/bin/authchanger"

# Ensure authchanger exists

if [ ! -f "$AUTHCHANGER" ]; then
    echo "Jamf Connect not installed — authchanger not found."
    exit 1
fi

# Get current authentication mechanism

CURRENT_MODE=$($AUTHCHANGER -print 2>/dev/null)

# Check if Jamf Connect login is already configured

if echo "$CURRENT_MODE" | grep -q "JamfConnectLogin:Success"; then
    echo "Jamf Connect is already active. No changes made."
else
    echo "Setting Jamf Connect as login mechanism..."
    "$AUTHCHANGER" -JamfConnect

    # Verify change was succesful

    NEW_MODE=$($AUTHCHANGER -print 2>/dev/null)
    if echo "$NEW_MODE" | grep -q "JamfConnectLogin:Success"; then
        echo "Jamf Connect login method successfully set."
    else
        echo "Warning: Jamf Connect login change may not have applied correctly."
    fi
fi
