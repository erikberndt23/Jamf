#!/bin/bash
#set -x

# User Defined variables

heimdalKEY=""   # Go to dashboard, Guide -> Your Heimdal Activation key
use_RC="false"   # Fasle to use production version, tru to download and install latest RC build

############################################################################################
##
## Generated variables. Please do not modiffy anything bellow this line
##
############################################################################################
theKeyIsValid="false"
appname="Heimdal Agent"
app="$appname.app"                                                                                              # The actual name of our App once installed
logandmetadir="/Library/HeimdalSecurity/PatchAssets/Logs/$appname"                                              # Location of the logs
processpath="/Applications/$appname/Contents/MacOS/$appname"                                                    # The process name of the App we are installing
terminateprocess="true"                                                                                         # Do we want to terminate the running process? If false we'll wait until its not running
autoUpdate="false"                                                                                               # Application updates itself, if already installed we should exit

weburl="https://heimdalqastorage.blob.core.windows.net/mac-agent-updates/prod/latest/HeimdalPackage.pkg"     # What is the Azure Blob Storage URL?
if [[ $use_RC == "true" ]]; then
    weburl="https://heimdalqastorage.blob.core.windows.net/mac-agent-updates/rc/latest/HeimdalPackage_rc.pkg"   # What is the Azure Blob Storage URL?
fi

tempdir=$(mktemp -d)
log="$logandmetadir/$appname.log"                                               # The location of the script log file
metafile="$logandmetadir/$appname.meta"                                         # The location of our meta file (for updates)
installStatus=0                                                                 # Install status
# function to delay script if the specified process is running
waitForProcess () {

    #################################################################################################################
    #################################################################################################################
    ##
    ##  Function to pause while a specified process is running
    ##
    ##  Functions used
    ##
    ##      None
    ##
    ##  Variables used
    ##
    ##      $1 = name of process to check for
    ##      $2 = length of delay (if missing, function to generate random delay between 10 and 60s)
    ##      $3 = true/false if = "true" terminate process, if "false" wait for it to close
    ##
    ###############################################################
    ###############################################################

    processName=$1
    fixedDelay=$2
    terminate=$3

    log " Waiting for other [$processName] processes to end"
    while ps aux | grep "$processName" | grep -v grep &>/dev/null; do

        if [[ $terminate == "true" ]]; then
            log " + [$appname] running, terminating [$processpath]..."
            pkill -f "$processName"
            return
        fi

        # If we've been passed a delay we should use it, otherwise we'll create a random delay each run
        if [[ ! $fixedDelay ]]; then
            delay=$(( $RANDOM % 50 + 10 ))
        else
            delay=$fixedDelay
        fi

        log "  + Another instance of $processName is running, waiting [$delay] seconds"
        sleep $delay
    done

    log " No instances of [$processName] found, safe to proceed"
}

# function to check if we need Rosetta 2
checkForRosetta2 () {

    #################################################################################################################
    #################################################################################################################
    ##
    ##  Simple function to install Rosetta 2 if needed.
    ##
    ##  Functions
    ##
    ##      waitForProcess (used to pause script if another instance of softwareupdate is running)
    ##
    ##  Variables
    ##
    ##      None
    ##
    ###############################################################
    ###############################################################


    log " Checking if we need Rosetta 2 or not"

    # if Software update is already running, we need to wait...
    waitForProcess "/usr/sbin/softwareupdate"


    ## Note, Rosetta detection code from https://derflounder.wordpress.com/2020/11/17/installing-rosetta-2-on-apple-silicon-macs/
    OLDIFS=$IFS
    IFS='.' read osvers_major osvers_minor osvers_dot_version <<< "$(/usr/bin/sw_vers -productVersion)"
    IFS=$OLDIFS

    if [[ ${osvers_major} -ge 11 ]]; then

        # Check to see if the Mac needs Rosetta installed by testing the processor

        processor=$(/usr/sbin/sysctl -n machdep.cpu.brand_string | grep -o "Intel")

        if [[ -n "$processor" ]]; then
            log " $processor processor installed. No need to install Rosetta."
        else

            # Check for Rosetta "oahd" process. If not found,
            # perform a non-interactive install of Rosetta.

            if /usr/bin/pgrep oahd >/dev/null 2>&1; then
                log " Rosetta is already installed and running. Nothing to do."
            else
                /usr/sbin/softwareupdate --install-rosetta --agree-to-license

                if [[ $? -eq 0 ]]; then
                    log " Rosetta has been successfully installed."
                else
                    log " Rosetta installation failed!"
                    exitcode=1
                fi
            fi
        fi
        else
            log " Mac is running macOS $osvers_major.$osvers_minor.$osvers_dot_version."
            log " No need to install Rosetta on this version of macOS."
    fi

}

# Function to detect if app installed on current endpoint
function is_app_installed() {

    #################################################################################################################
    #################################################################################################################
    ##
    ##  This function takes the following parameters and checks if the app with the specified bundle identifier is installed or not
    ##
    ##  Functions
    ##
    ##      none
    ##
    ##  Variables
    ##
    ##      $1 = the bundle identifier of the app that need to be checked
    ##
    ##  Notes
    ##
    ##      Return 0 if the app was found, 1 otherwhise
    ##
    ###############################################################
    ###############################################################


    local bundle_id="$1"
    local app_path

    app_path=$(osascript -e "id of app id \"$bundle_id\"")

    # Check if the bundle ID returned matches the given ID (i.e., it was found)
    if [[ "$app_path" == "$bundle_id" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to update the last modified date for this app
fetchLastModifiedDate() {

    #################################################################################################################
    #################################################################################################################
    ##
    ##  This function takes the following global variables and downloads the URL provided to a temporary location
    ##
    ##  Functions
    ##
    ##      none
    ##
    ##  Variables
    ##
    ##      $logandmetadir = Directory to read nand write meta data to
    ##      $metafile = Location of meta file (used to store last update time)
    ##      $weburl = URL of download location
    ##      $tempfile = location of temporary DMG file downloaded
    ##      $lastmodified = Generated by the function as the last-modified http header from the curl request
    ##
    ##  Notes
    ##
    ##      If called with "fetchLastModifiedDate update" the function will overwrite the current lastmodified date into metafile
    ##
    ###############################################################
    ###############################################################

    ## Check if the log directory has been created
    if [[ ! -d "$logandmetadir" ]]; then
        ## Creating Metadirectory
        log " Creating [$logandmetadir] to store metadata"
        mkdir -p "$logandmetadir"
    fi

    # generate the last modified date of the file we need to download
    lastmodified=$(curl -sIL "$weburl" | grep -i "last-modified" | awk '{$1=""; print $0}' | awk '{ sub(/^[ \t]+/, ""); print }' | tr -d '\r')

    if [[ $1 == "update" ]]; then
        log " Writing last modifieddate [$lastmodified] to [$metafile]"
        log "$lastmodified" > "$metafile"
    fi

}

function downloadApp () {

    #################################################################################################################
    #################################################################################################################
    ##
    ##  This function takes the following global variables and downloads the URL provided to a temporary location
    ##
    ##  Functions
    ##
    ##      waitForCurl (Pauses download until all other instances of Curl have finished)
    ##      downloadSize (Generates human readable size of the download for the logs)
    ##
    ##  Variables
    ##
    ##      $appname = Description of the App we are installing
    ##      $weburl = URL of download location
    ##      $tempfile = location of temporary DMG file downloaded
    ##
    ###############################################################
    ###############################################################

    log " Starting downlading of [$appname]"

    # wait for other downloads to complete
    waitForProcess "curl -f"

    #download the file
    updateOctory installing
    log " Downloading $appname [$weburl]"

    cd "$tempdir"
    log " Is the key is vsalid: $theKeyIsValid"
    if [[ $theKeyIsValid == "true" ]]; then
        #Download and install agent without using a key
        log "  The key is $heimdalKEY"
        curl -f -s --connect-timeout 30 --retry 5 --retry-delay 60 --compressed -L -J -o "$heimdalKEY.pkg" "$weburl"
    else
        #Download and install agent without using a key
        curl -f -s --connect-timeout 30 --retry 5 --retry-delay 60 --compressed -L -J -O "$weburl"
    fi

    if [ $? == 0 ]; then

            # We have downloaded a file, we need to know what the file is called and what type of file it is
            tempSearchPath="$tempdir/*"
            for f in $tempSearchPath; do
                tempfile=$f
            done

            case $tempfile in

            *.pkg|*.PKG|*.mpkg|*.MPKG)
                packageType="PKG"
                ;;

            *.zip|*.ZIP)
                packageType="ZIP"
                ;;

            *.tbz2|*.TBZ2|*.bz2|*.BZ2)
                packageType="BZ2"
                ;;

            *.dmg|*.DMG)


                # We have what we think is a DMG, but we don't know what is inside it yet, could be an APP or PKG
                # Let's mount it and try to guess what we're dealing with...
                log " Found DMG, looking inside..."

                # Mount the dmg file...
                volume="$tempdir/$appname"
                log " Mounting Image [$volume] [$tempfile]"
                hdiutil attach -quiet -nobrowse -mountpoint "$volume" "$tempfile"
                if [ "$?" = "0" ]; then
                    log " Mounted succesfully to [$volume]"
                else
                    log " Failed to mount [$tempfile]"

                fi

                if  [[ $(ls "$volume" | grep -i .app) ]] && [[ $(ls "$volume" | grep -i .pkg) ]]; then

                    log " Detected both APP and PKG in same DMG, exiting gracefully"

                else

                    if  [[ $(ls "$volume" | grep -i .app) ]]; then
                        log " Detected APP, setting PackageType to DMG"
                        packageType="DMG"
                    fi

                    if  [[ $(ls "$volume" | grep -i .pkg) ]]; then
                        log " Detected PKG, setting PackageType to DMGPKG"
                        packageType="DMGPKG"
                    fi

                    if  [[ $(ls "$volume" | grep -i .mpkg) ]]; then
                        log " Detected PKG, setting PackageType to DMGPKG"
                        packageType="DMGPKG"
                    fi

                fi

                # Unmount the dmg
                log " Un-mounting [$volume]"
                hdiutil detach -quiet "$volume"
                ;;

            *)
                # We can't tell what this is by the file name, lets look at the metadata
                log " Unknown file type [$f], analysing metadata"
                metadata=$(file -z "$tempfile")

                if [[ "$metadata" == *"Zip archive data"* ]]; then
                packageType="ZIP"
                mv "$tempfile" "$tempdir/install.zip"
                tempfile="$tempdir/install.zip"
                fi

                if [[ "$metadata" == *"xar archive"* ]]; then
                packageType="PKG"
                mv "$tempfile" "$tempdir/install.pkg"
                tempfile="$tempdir/install.pkg"
                fi

                if [[ "$metadata" == *"DOS/MBR boot sector, extended partition table"* ]] || [[ "$metadata" == *"Apple Driver Map"* ]] ; then
                packageType="DMG"
                mv "$tempfile" "$tempdir/install.dmg"
                tempfile="$tempdir/install.dmg"
                fi

                if [[ "$metadata" == *"POSIX tar archive (bzip2 compressed data"* ]]; then
                packageType="BZ2"
                mv "$tempfile" "$tempdir/install.tar.bz2"
                tempfile="$tempdir/install.tar.bz2"
                fi
                ;;
            esac

            if [[ ! $packageType ]]; then
                log "Failed to determine temp file type [$metadata]"
                rm -rf "$tempdir"
            else
                log " Downloaded [$app] to [$tempfile]"
                log " Detected install type as [$packageType]"
            fi

    else

         log " Failure to download [$weburl] to [$tempfile]"
         updateOctory failed

         installStatus=1
    fi

}

# Function to check if we need to update or not
function updateCheck() {

    #################################################################################################################
    #################################################################################################################
    ##
    ##  This function takes the following dependencies and variables and exits if no update is required
    ##
    ##  Functions
    ##
    ##      fetchLastModifiedDate
    ##
    ##  Variables
    ##
    ##      $appname = Description of the App we are installing
    ##      $tempfile = location of temporary DMG file downloaded
    ##      $volume = name of volume mount point
    ##      $app = name of Application directory under /Applications
    ##
    ###############################################################
    ###############################################################


    log " Checking if we need to install or update [$appname]"

    ## Is the app already installed?
    if [ -d "/Applications/$app" ]; then

    # App is installed, if it's updates are handled by MAU we should quietly exit
    if [[ $autoUpdate == "true" ]]; then
        log " [$appname] is already installed and handles updates itself, exiting"
        installStatus=0;
    fi

    # App is already installed, we need to determine if it requires updating or not
        log " [$appname] already installed, let's see if we need to update"
        fetchLastModifiedDate

        ## Did we store the last modified date last time we installed/updated?
        if [[ -d "$logandmetadir" ]]; then

            if [ -f "$metafile" ]; then
                previouslastmodifieddate=$(cat "$metafile")
                if [[ "$previouslastmodifieddate" != "$lastmodified" ]]; then
                    log " Update found, previous [$previouslastmodifieddate] and current [$lastmodified]"
                    update="update"
                else
                    log " No update between previous [$previouslastmodifieddate] and current [$lastmodified]"
                    log " Exiting, nothing to do"
                    installStatus=0
                fi
            else
                log " Meta file [$metafile] not found"
                log " Unable to determine if update required, updating [$appname] anyway"

            fi

        fi

    else
        log " [$appname] not installed, need to download and install"
    fi

}

## Install PKG Function
function installPKG () {

    #################################################################################################################
    #################################################################################################################
    ##
    ##  This function takes the following global variables and installs the PKG file
    ##
    ##  Functions
    ##
    ##      isAppRunning (Pauses installation if the process defined in global variable $processpath is running )
    ##      fetchLastModifiedDate (Called with update flag which causes the function to write the new lastmodified date to the metadata file)
    ##
    ##  Variables
    ##
    ##      $appname = Description of the App we are installing
    ##      $tempfile = location of temporary DMG file downloaded
    ##      $volume = name of volume mount point
    ##      $app = name of Application directory under /Applications
    ##
    ###############################################################
    ###############################################################


    # Check if app is running, if it is we need to wait.
    waitForProcess "$processpath" "300" "$terminateprocess"

    log " Installing $appname"


    # Update Octory monitor
    updateOctory installing

    # Remove existing files if present
    if [[ -d "/Applications/$app" ]]; then
        rm -rf "/Applications/$app"
    fi

    installer -pkg "$tempfile" -target /Applications

    # Checking if the app was installed successfully
    if [ "$?" = "0" ]; then

        log " $appname Installed"
        log " Cleaning Up"
        rm -rf "$tempdir"

        log " Application [$appname] succesfully installed"
        fetchLastModifiedDate update
        updateOctory installed
        installStatus=0

    else

        log " Failed to install $appname"
        rm -rf "$tempdir"
        updateOctory failed
        installStatus=1
    fi

}

## Install DMG Function
function installDMGPKG () {

    #################################################################################################################
    #################################################################################################################
    ##
    ##  This function takes the following global variables and installs the DMG file into /Applications
    ##
    ##  Functions
    ##
    ##      isAppRunning (Pauses installation if the process defined in global variable $processpath is running )
    ##      fetchLastModifiedDate (Called with update flag which causes the function to write the new lastmodified date to the metadata file)
    ##
    ##  Variables
    ##
    ##      $appname = Description of the App we are installing
    ##      $tempfile = location of temporary DMG file downloaded
    ##      $volume = name of volume mount point
    ##      $app = name of Application directory under /Applications
    ##
    ###############################################################
    ###############################################################


    # Check if app is running, if it is we need to wait.
    waitForProcess "$processpath" "300" "$terminateprocess"

    log " Installing [$appname]"
    updateOctory installing

    # Mount the dmg file...
    volume="$tempdir/$appname"
    log " Mounting Image"
    hdiutil attach -quiet -nobrowse -mountpoint "$volume" "$tempfile"

    # Remove existing files if present
    if [[ -d "/Applications/$app" ]]; then
        log " Removing existing files"
        rm -rf "/Applications/$app"
    fi

    for file in "$volume"/*.pkg
    do
        log " Starting installer for [$file]"
        installer -pkg "$file" -target /Applications
    done

    for file in "$volume"/*.mpkg
    do
        log " Starting installer for [$file]"
        installer -pkg "$file" -target /Applications
    done

    # Unmount the dmg
    log " Un-mounting [$volume]"
    hdiutil detach -quiet "$volume"

    # Checking if the app was installed successfully

    if [[ -a "/Applications/$app" ]]; then

        log " [$appname] Installed"
        log " Cleaning Up"
        rm -rf "$tempfile"

        log " Fixing up permissions"
        sudo chown -R root:wheel "/Applications/$app"
        log " Application [$appname] succesfully installed"
        fetchLastModifiedDate update
        updateOctory installed
        installStatus=0
    else
        log " Failed to install [$appname]"
        rm -rf "$tempdir"
        updateOctory failed
        installStatus=1
    fi

}


## Install DMG Function
function installDMG () {

    #################################################################################################################
    #################################################################################################################
    ##
    ##  This function takes the following global variables and installs the DMG file into /Applications
    ##
    ##  Functions
    ##
    ##      isAppRunning (Pauses installation if the process defined in global variable $processpath is running )
    ##      fetchLastModifiedDate (Called with update flag which causes the function to write the new lastmodified date to the metadata file)
    ##
    ##  Variables
    ##
    ##      $appname = Description of the App we are installing
    ##      $tempfile = location of temporary DMG file downloaded
    ##      $volume = name of volume mount point
    ##      $app = name of Application directory under /Applications
    ##
    ###############################################################
    ###############################################################


    # Check if app is running, if it is we need to wait.
    waitForProcess "$processpath" "300" "$terminateprocess"



    log " Installing [$appname]"
    updateOctory installing

    # Mount the dmg file...
    volume="$tempdir/$appname"
    log " Mounting Image"
    hdiutil attach -quiet -nobrowse -mountpoint "$volume" "$tempfile"

    # Remove existing files if present
    if [[ -d "/Applications/$app" ]]; then
        log " Removing existing files"
        rm -rf "/Applications/$app"
    fi

    # Sync the application and unmount once complete
    log " Copying app files to /Applications/$app"
    rsync -a "$volume"/*.app/ "/Applications/$app"

    # Unmount the dmg
    log " Un-mounting [$volume]"
    hdiutil detach -quiet "$volume"

    # Checking if the app was installed successfully

    if [[ -a "/Applications/$app" ]]; then

        log " [$appname] Installed"
        log " Cleaning Up"
        rm -rf "$tempfile"

        log " Fixing up permissions"
        sudo chown -R root:wheel "/Applications/$app"
        log " Application [$appname] succesfully installed"
        fetchLastModifiedDate update
        updateOctory installed
        installStatus=0
    else
        log " Failed to install [$appname]"
        rm -rf "$tempdir"
        updateOctory failed
        installStatus=1
    fi

}

## Install ZIP Function
function installZIP () {

    #################################################################################################################
    #################################################################################################################
    ##
    ##  This function takes the following global variables and installs the DMG file into /Applications
    ##
    ##  Functions
    ##
    ##      isAppRunning (Pauses installation if the process defined in global variable $processpath is running )
    ##      fetchLastModifiedDate (Called with update flag which causes the function to write the new lastmodified date to the metadata file)
    ##
    ##  Variables
    ##
    ##      $appname = Description of the App we are installing
    ##      $tempfile = location of temporary DMG file downloaded
    ##      $volume = name of volume mount point
    ##      $app = name of Application directory under /Applications
    ##
    ###############################################################
    ###############################################################


    # Check if app is running, if it is we need to wait.
    waitForProcess "$processpath" "300" "$terminateprocess"

    log " Installing $appname"
    updateOctory installing

    # Change into temp dir
    cd "$tempdir"
    if [ "$?" = "0" ]; then
      log " Changed current directory to $tempdir"
    else
      log " failed to change to $tempfile"
      if [ -d "$tempdir" ]; then rm -rf $tempdir; fi
      updateOctory failed
      installStatus=1
    fi

    # Unzip files in temp dir
    unzip -qq -o "$tempfile"
    if [ "$?" = "0" ]; then
      log " $tempfile unzipped"
    else
      log " failed to unzip $tempfile"
      if [ -d "$tempdir" ]; then rm -rf $tempdir; fi
      updateOctory failed
      installStatus=1
    fi

    # If app is already installed, remove all old files
    if [[ -a "/Applications/$app" ]]; then

      log " Removing old installation at /Applications/$app"
      rm -rf "/Applications/$app"

    fi
    # Copy over new files
    rsync -a "$app/" "/Applications/$app"
    if [ "$?" = "0" ]; then
      log " $appname moved into /Applications"
    else
      log " failed to move $appname to /Applications"
      if [ -d "$tempdir" ]; then rm -rf $tempdir; fi
      updateOctory failed
      installStatus=1
    fi

    # Make sure permissions are correct
    log " Fix up permissions"
    sudo chown -R root:wheel "/Applications/$app"
    if [ "$?" = "0" ]; then
      log " correctly applied permissions to $appname"
    else
      log " failed to apply permissions to $appname"
      if [ -d "$tempdir" ]; then rm -rf $tempdir; fi
      updateOctory failed
      installStatus=1
    fi

    # Checking if the app was installed successfully
    if [ "$?" = "0" ]; then
        if [[ -a "/Applications/$app" ]]; then

            log " $appname Installed"
            updateOctory installed
            log " Cleaning Up"
            rm -rf "$tempfile"

            # Update metadata
            fetchLastModifiedDate update

            log " Fixing up permissions"
            sudo chown -R root:wheel "/Applications/$app"
            log " Application [$appname] succesfully installed"
            installStatus=0
        else
            log " Failed to install $appname"
            installStatus=1
        fi
    else

        # Something went wrong here, either the download failed or the install Failed
        # intune will pick up the exit status and the IT Pro can use that to determine what went wrong.
        # Intune can also return the log file if requested by the admin

        log " Failed to install $appname"
        if [ -d "$tempdir" ]; then rm -rf $tempdir; fi
        installStatus=1
    fi
}

## Install BZ2 Function
function installBZ2 () {

    #################################################################################################################
    #################################################################################################################
    ##
    ##  This function takes the following global variables and installs the DMG file into /Applications
    ##
    ##  Functions
    ##
    ##      isAppRunning (Pauses installation if the process defined in global variable $processpath is running )
    ##      fetchLastModifiedDate (Called with update flag which causes the function to write the new lastmodified date to the metadata file)
    ##
    ##  Variables
    ##
    ##      $appname = Description of the App we are installing
    ##      $tempfile = location of temporary DMG file downloaded
    ##      $volume = name of volume mount point
    ##      $app = name of Application directory under /Applications
    ##
    ###############################################################
    ###############################################################


    # Check if app is running, if it is we need to wait.
    waitForProcess "$processpath" "300" "$terminateprocess"

    log " Installing $appname"
    updateOctory installing

    # Change into temp dir
    cd "$tempdir"
    if [ "$?" = "0" ]; then
      log " Changed current directory to $tempdir"
    else
      log " failed to change to $tempfile"
      if [ -d "$tempdir" ]; then rm -rf $tempdir; fi
      updateOctory failed
      installStatus=1
    fi

    # Unzip files in temp dir
    tar -jxf "$tempfile"
    if [ "$?" = "0" ]; then
      log " $tempfile uncompressed"
    else
      log " failed to uncompress $tempfile"
      if [ -d "$tempdir" ]; then rm -rf $tempdir; fi
      updateOctory failed
      installStatus=1
    fi

    # If app is already installed, remove all old files
    if [[ -a "/Applications/$app" ]]; then

      log " Removing old installation at /Applications/$app"
      rm -rf "/Applications/$app"

    fi

    # Copy over new files
    rsync -a "$app/" "/Applications/$app"
    if [ "$?" = "0" ]; then
      log " $appname moved into /Applications"
    else
      log " failed to move $appname to /Applications"
      if [ -d "$tempdir" ]; then rm -rf $tempdir; fi
      updateOctory failed
      installStatus=1
    fi

    # Make sure permissions are correct
    log " Fix up permissions"
    sudo chown -R root:wheel "/Applications/$app"
    if [ "$?" = "0" ]; then
      log " correctly applied permissions to $appname"
    else
      log " failed to apply permissions to $appname"
      if [ -d "$tempdir" ]; then rm -rf $tempdir; fi
      updateOctory failed
      installStatus=1
    fi

    # Checking if the app was installed successfully
    if [ "$?" = "0" ]; then
        if [[ -a "/Applications/$app" ]]; then

            log " $appname Installed"
            updateOctory installed
            log " Cleaning Up"
            rm -rf "$tempfile"

            # Update metadata
            fetchLastModifiedDate update

            log " Fixing up permissions"
            sudo chown -R root:wheel "/Applications/$app"
            log " Application [$appname] succesfully installed"
            installStatus=0
        else
            log " Failed to install $appname"
            installStatus=1
        fi
    else

        # Something went wrong here, either the download failed or the install Failed
        # intune will pick up the exit status and the IT Pro can use that to determine what went wrong.
        # Intune can also return the log file if requested by the admin

        log " Failed to install $appname"
        if [ -d "$tempdir" ]; then rm -rf $tempdir; fi
        installStatus=1
    fi
}

function updateOctory () {

    #################################################################################################################
    #################################################################################################################
    ##
    ##  This function is designed to update Octory status (if required)
    ##
    ##
    ##  Parameters (updateOctory parameter)
    ##
    ##      notInstalled
    ##      installing
    ##      installed
    ##
    ###############################################################
    ###############################################################

    # Is Octory present
    if [[ -a "/Library/Application Support/Octory" ]]; then

        # Octory is installed, but is it running?
        if [[ $(ps aux | grep -i "Octory" | grep -v grep) ]]; then
            log " Updating Octory monitor for [$appname] to [$1]"
            /usr/local/bin/octo-notifier monitor "$appname" --state $1 >/dev/null
        fi
    fi

}

function startLog() {

    ###################################################
    ###################################################
    ##
    ##  start logging - Output to log file and STDOUT
    ##
    ####################
    ####################

    #keep old logs if exists.
    if [ -f "$log" ]
    then
      # Add some lines to visually see where a new install starts.
        echo "" >> "$log"
    else

        ## Creating Metadirectory and intermediary path
        mkdir -p "$logandmetadir"
        ## Create the log file
        echo "" > "$log"
    fi
}


# function to delay until the user has finished setup assistant.
waitForDesktop () {
  until ps aux | grep /System/Library/CoreServices/Dock.app/Contents/MacOS/Dock | grep -v grep &>/dev/null; do
    delay=$(( $RANDOM % 50 + 10 ))
    log "  + Dock not running, waiting [$delay] seconds"
    sleep $delay
  done
  log " Dock is here, lets carry on"
}

log() {
 echo "`date` | $1"
 echo "`date`: $1" >> $log
}


# Validate launch parameters
launch_app() {

  # Check if the string is empty
  if [ -z "$heimdalKEY" ]; then
      log "The heimdalKEY is empty"
  else
    log "A kwey was provided inside the script"
    UUID_KEY="$heimdalKEY"
    theKeyIsValid="true"
    return
  fi

  UUID_KEY="$1"
  PATTERN_KEY="^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"

  if [[ ! -n "$UUID_KEY" ]]; then
    log " No Key provided as parametter"
    UUID_KEY="$heimdalKEY"
  else
    log " A key was provided: $UUID_KEY"
  fi

  if [[ $UUID_KEY =~ $PATTERN_KEY ]]; then
    log " The key is in the right format. Perform install using this key: $UUID_KEY"
    theKeyIsValid="true"
    heimdalKEY="$UUID_KEY"

  else
    log " The  key is NOT the right format or is empty. Perform install without  key "
  fi

}


    ###################################################
    ###################################################
    ##
    ##  find and terminate any old thor proccess [mainly because ui proccess in some cases remains in place along with the new agent]
    ##
    ####################
    ####################
terminate_processes_with_thor() {
    log "Terminate old procceses for thor agent - if any"
    # Use pgrep to search for processes that have 'thor' in their name
    for pid in $(pgrep -i thor); do
        # Extract the process name for the PID
        process_name=$(ps -p $pid -o comm=)
        log "Terminating process with name: $process_name and PID: $pid"
        kill -9 $pid
    done
}

###################################################################################
###################################################################################
##
## Begin Script Body
##
#####################################
#####################################

# Initiate logging
startLog




log ""
log "##############################################################"
log "#  Logging install of [$appname] to [$log]"
log "############################################################"
log ""

# Check for the Heimdal Agent
 if is_app_installed "com.heimdalsecurity.heimdalAgent"; then
     log "The Heimdal Agent has been successfully detected on this system. Future updates will be managed by the agent. Terminating process."
     exit 0;
 fi

# Validate the parameters and start installer
launch_app "$1"

# Install Rosetta if we need it
checkForRosetta2

# Test if we need to install or update
updateCheck

# Wait for Desktop
waitForDesktop

# Download app
downloadApp

# Install PKG file
if [[ $packageType == "PKG" ]]; then
    installPKG
fi

# Install PKG file
if [[ $packageType == "ZIP" ]]; then
    installZIP
fi

# Install PKG file
if [[ $packageType == "BZ2" ]]; then
    installBZ2
fi

# Install PKG file
if [[ $packageType == "DMG" ]]; then
    installDMG
fi

# Install DMGPKG file
if [[ $packageType == "DMGPKG" ]]; then
    installDMGPKG
fi


terminate_processes_with_thor
log "Wait 10 seconds..."
sleep 10
terminate_processes_with_thor

exit $installStatus;
