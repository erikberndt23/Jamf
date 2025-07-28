#!/bin/bash

# Get app name from Jamf Pro parameter 4
APP_NAME="$4"

if [ -z "$APP_NAME" ]; then
    echo "Error: No app name provided. Under options, set Parameter 4 to the app name (e.g., 'Tunnelblick','Slack','Zoom')."
    exit 1
fi

APP_PATH="/Applications/${APP_NAME}.app"

echo "Attempting to uninstall $APP_NAME..."

# Quit the app if running
if pgrep -ix "$APP_NAME" > /dev/null; then
    echo "Quitting $APP_NAME..."
    osascript -e "tell application \"$APP_NAME\" to quit"
    sleep 2
fi

# Remove the application
if [ -d "$APP_PATH" ]; then
    echo "Removing $APP_PATH..."
    rm -rf "$APP_PATH"
else
    echo "$APP_PATH not found."
fi

# Optional: Remove user and system support files
declare -a SUPPORT_PATHS=(
    "$HOME/Library/Application Support/$APP_NAME"
    "$HOME/Library/Preferences/com.${APP_NAME,,}*.plist"
    "/Library/Application Support/$APP_NAME"
    "/Library/Preferences/com.${APP_NAME,,}*.plist"
)

echo "Removing support files..."

for path in "${SUPPORT_PATHS[@]}"; do
    files=$(eval ls $path 2>/dev/null)
    for file in $files; do
        echo "Removing $file"
        rm -rf "$file"
    done
done

echo "$APP_NAME uninstall complete."
exit 0