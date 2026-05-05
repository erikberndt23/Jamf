#!/bin/bash

# Get DNS Servers — Jamf Pro Extension Attribute
# Returns all configured DNS servers for all active network services. 
# Makes visible in computer inventory in Jamf Pro.


result=""

while IFS= read -r service; do
    dns=$(networksetup -getdnsservers "$service" 2>/dev/null)
    if echo "$dns" | grep -qE "^There aren't"; then
        continue
    fi
    while IFS= read -r server; do
        result+="${service}: ${server}\n"
    done <<< "$dns"
done < <(networksetup -listallnetworkservices 2>/dev/null | tail -n +2)

# Fallback to resolv.conf if nothing found
if [[ -z "$result" ]]; then
    while read -r _ ip; do
        result+="resolv.conf: ${ip}\n"
    done < <(grep '^nameserver' /etc/resolv.conf 2>/dev/null)
fi

if [[ -z "$result" ]]; then
    result="No DNS servers found"
fi