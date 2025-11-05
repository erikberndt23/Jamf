#!/bin/bash
# Uninstall Disable Veeam Backups on VPN package

PLIST="/Library/LaunchDaemons/com.asti.preventvpnbackup.plist"
SCRIPT="/usr/local/bin/prevent-vpn-backup.sh"
LOG="/var/log/prevent-vpn-backup.log"

# Unload and remove LaunchDaemon

if [ -f "$PLIST" ]; then
    echo "Unloading LaunchDaemon..."
    launchctl bootout system "$PLIST" 2>/dev/null || true
    rm -f "$PLIST"
    echo "Removed LaunchDaemon: $PLIST"
fi

# Remove the script

if [ -f "$SCRIPT" ]; then
    rm -f "$SCRIPT"
    echo "Removed script: $SCRIPT"
fi

# Remove the log file

if [ -f "$LOG" ]; then
    rm -f "$LOG"
    echo "Removed log file: $LOG"
fi

# Forget the pkg receipt

pkgutil --forget com.asti.preventvpnbackup 2>/dev/null || true

exit 0
