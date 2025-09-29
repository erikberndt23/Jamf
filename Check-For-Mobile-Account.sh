#!/bin/bash

# Get the currently logged-in console user

USERNAME=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && $3 != "loginwindow" { print $3 }')

# If no user is logged in

if [[ -z "$USERNAME" ]]; then
    echo "<result>No user logged in</result>"
    exit 0
fi

# Check if the user exists

if id "$USERNAME" &>/dev/null; then
    # Check if it's a mobile account
    if dscl . read /Users/"$USERNAME" AuthenticationAuthority 2>/dev/null | grep -q "LocalCachedUser"; then
        echo "<result>Yes</result>"
    else
        echo "<result>No</result>"
    fi
else
    echo "<result>User Not Found</result>"
fi
