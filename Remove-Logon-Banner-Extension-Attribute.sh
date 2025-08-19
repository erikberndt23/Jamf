#!/bin/bash
# Checks if old PolicyBanner.rtf exists

BANNER_FILE="/Library/Security/PolicyBanner.rtf"

if [ -f "$BANNER_FILE" ]; then
    echo "<result>Present</result>"
else
    echo "<result>Not Present</result>"
fi