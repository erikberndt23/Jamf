#!/bin/bash

# Username to check and potentially remove
USERNAME="lcadmin"

# Check if the lcadmin account exists and is hidden
if dscl . list /Users/ IsHidden 1 | grep -q "^$USERNAME$"; then
    echo "<result>Yes</result>"
    echo "Attempting to remove user $USERNAME..."

    # Remove user with jamf binary
    /usr/local/bin/jamf deleteAccount -username "$USERNAME" -deleteHomeDirectory

    if [[ $? -eq 0 ]]; then
        echo "User $USERNAME removed successfully."
    else
        echo "Failed to remove user $USERNAME."
    fi
else
    echo "<result>No</result>"
fi
