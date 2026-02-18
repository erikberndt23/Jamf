#!/bin/bash
# Install PDQ Detect Footprint Agent for Macs
echo "Downloading PDQ Detect agent installer..."

/usr/bin/curl -fL -o "/Library/Application Support/JAMF/tmp/footprint-agent-installer.sh" "https://footprint.codacloud.net/agent/macos/update/agent_installer.sh"

chmod +x "/Library/Application Support/JAMF/tmp/footprint-agent-installer.sh"

echo "Running installer..."

/bin/bash "/Library/Application Support/JAMF/tmp/footprint-agent-installer.sh" --token "$4" --server_url "https://detect.pdq.com"

RESULT=$?

if [ $RESULT -eq 0 ]; then
    echo "PDQ Detect agent installed successfully."
else
    echo "PDQ Detect agent install failed with exit code $RESULT."
fi

rm -f "/Library/Application Support/JAMF/tmp/footprint-agent-installer.sh"

exit $RESULT