#!/bin/bash

# Uninstall Tunneblick
echo "Uninstalling Tunnelblick..."

# Quit Tunnelblick if running
if pgrep -x "Tunnelblick" > /dev/null; then
    echo "Quitting Tunnelblick..."
    osascript -e 'quit app "Tunnelblick"'
    sleep 2
fi

# Tunnelblick paths to remove
declare -a pathsToRemove=(
    "/Applications/Tunnelblick.app"
    "$HOME/Library/Application Support/Tunnelblick"
    "$HOME/Library/Preferences/net.tunnelblick.tunnelblick.plist"
    "/Library/Application Support/Tunnelblick"
    "/Library/PrivilegedHelperTools/net.tunnelblick.tunnelblick.tunnelblickd"
    "/Library/LaunchDaemons/net.tunnelblick.tunnelblick.tunnelblickd.plist"
)

# Remove the paths
for path in "${pathsToRemove[@]}"; do
    if [ -e "$path" ]; then
        echo "Removing: $path"
        sudo rm -rf "$path"
    fi
done

# Forget Tunnelblick package receipt if installed via pkg
if /usr/sbin/pkgutil --pkgs | grep -q "net.tunnelblick.tunnelblick"; then
    echo "Forgetting package receipt..."
    sudo /usr/sbin/pkgutil --forget "net.tunnelblick.tunnelblick"
fi

echo "Tunnelblick uninstall completed."
exit 0
