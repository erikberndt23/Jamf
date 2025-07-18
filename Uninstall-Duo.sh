#!/bin/bash

echo "Uninstall Duo Maclogon..."

# Locate and remove Duo MacLogon launch daemon (if it exists)
if [ -f /Library/LaunchDaemons/com.duosecurity.maclogon.plist ]; then
    echo "Unloading and removing LaunchDaemon..."
    launchctl bootout system /Library/LaunchDaemons/com.duosecurity.maclogon.plist 2>/dev/null
    rm -f /Library/LaunchDaemons/com.duosecurity.maclogon.plist
fi

# Remove Duo MacLogon PAM module and related files
echo "Removing Duo files..."
rm -f /usr/local/lib/pam/pam_duo.so
rm -f /etc/duo/pam_duo.conf
rm -rf /etc/duo

# Restore default /etc/pam.d files if they were modified
# Optional: You may want to use backup copies or JAMF-managed config

# Remove the Duo MacLogon package receipt
PKG_ID=$(pkgutil --pkgs | grep -i "com.duosecurity.Maclogon")

if [ -n "$PKG_ID" ]; then
    echo "Forgetting receipt: $PKG_ID"
    sudo pkgutil --forget "$PKG_ID"
else
    echo "No Duo MacLogon receipt found."
fi

echo "Duo MacLogon uninstallation complete!"
exit 0
