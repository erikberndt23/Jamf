#!/bin/bash

# Values are stored as secure parameters in Jamf
AD_USERNAME="$4"
AD_PASSWORD="$5"

# Unbind from Active Directory
echo "Unbinding from Active Directory..."

AD_DOMAIN=$(dsconfigad -show | awk '/Active Directory Domain/{print $NF}')

if [[ -n "$AD_DOMAIN" ]]; then
    /usr/sbin/dsconfigad -force -remove -u "$AD_USERNAME" -p "$AD_PASSWORD"
    RESULT=$?

    if [[ $RESULT -eq 0 ]]; then
        echo "Successfully unbound from $AD_DOMAIN"
    else
        echo "Failed to unbind from $AD_DOMAIN"
        exit 1
    fi
else
    echo "Not currently bound to Active Directory."
fi

exit 0