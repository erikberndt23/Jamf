#!/bin/bash

# Check for Duo MacLogon package
if pkgutil --pkgs | grep -qi "com.duosecurity.Maclogon"; then
    echo "<result>Installed</result>"
else
    echo "<result>Not Installed</result>"
fi