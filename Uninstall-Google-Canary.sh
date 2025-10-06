#!/bin/bash

echo "Starting Google Chrome Canary uninstallation..."

# Quit Chrome Canary if running
echo "Quitting Google Chrome Canary..."
osascript -e 'tell application "Google Chrome Canary" to quit'

# Remove the main application
echo "Removing /Applications/Google Chrome Canary.app..."
rm -rf "/Applications/Google Chrome Canary.app"

# Remove supporting files in /Library
echo "Removing supporting files from /Library..."
rm -rf "/Library/Application Support/Google/Chrome Canary"
rm -rf "/Library/Preferences/com.google.Chrome.canary.plist"
rm -rf "/Library/Caches/Google/Chrome Canary"

# Remove user library files
echo "Removing user library files..."
rm -rf ~/Library/Application\ Support/Google/Chrome\ Canary
rm -rf ~/Library/Preferences/com.google.Chrome.canary.plist
rm -rf ~/Library/Caches/Google/Chrome\ Canary
rm -rf ~/Library/Saved\ Application\ State/com.google.Chrome.canary.savedState

echo "Google Chrome Canary uninstallation complete."
exit 0
