#!/bin/bash

# Username to check
USERNAME="lcadmin"

# Check if the lcadmin account exists as a standard user
if dscl . list /Users/ IsHidden 1 >/dev/null 2>&1 | grep '$USERNAME'; then
    echo "<result>Yes</result>"
else
    echo "<result>No</result>"
fi