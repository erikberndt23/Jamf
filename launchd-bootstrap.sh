#!/bin/bash
# Load the LaunchDaemon if not already loaded
if [ -f "/Library/LaunchDaemons/com.asti.preventvpnbackup.plist" ]; then
launchctl bootstrap system /Library/LaunchDaemons/com.asti.preventvpnbackup.plist 2>/dev/null || true
fi
exit 0