#!/bin/bash

# IP Configuration — Jamf Pro Extension Attribute
# Returns "DHCP" or "Static" for the active interface.

while IFS= read -r service; do
    info=$(networksetup -getinfo "$service" 2>/dev/null)

    # Skip services with no IP assigned
    ip=$(echo "$info" | awk -F': ' '/^IP address/{print $2}')
    if [[ -z "$ip" || "$ip" == "none" ]]; then
        continue
    fi

    # Method is on the first line, e.g. "DHCP Configuration" or "Manual Configuration"
    first_line=$(echo "$info" | head -1)

    case "$first_line" in
        "DHCP Configuration")   echo "<result>DHCP</result>"; exit 0 ;;
        "Manual Configuration") echo "<result>Static</result>"; exit 0 ;;
    esac

done < <(networksetup -listallnetworkservices 2>/dev/null | tail -n +2)