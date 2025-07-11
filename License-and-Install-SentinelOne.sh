#!/bin/zsh
# This will install SentinelOne and add the site token during the install
echo "<SentinelOne Site Token>" > "/Library/Application Support/JAMF/Waiting Room/com.sentinelone.registration-token"
/usr/sbin/installer -pkg "/Library/Application Support/JAMF/Waiting Room/Sentinel-Release-25-1-2-8039_macos_v25_1_2_8039.pkg" -target /