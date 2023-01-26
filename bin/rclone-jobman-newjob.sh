#!/usr/bin/env bash

###################################################################
#Script Name : rclone-jobman-newjob.sh
#Description : For use with rclone-jobman.sh. Sets up a new job.
#Args        : -
#Author      : CarlesCN
#E-mail      : drtlof@gmail.com
###################################################################

# -e script ends on error (exit != 0)
# -u error if undefined variable
# -o pipefail script ends if piped command fails
set -euo pipefail

readonly scriptName="rclone-jobman-newjob.sh"
readonly confPath="$HOME/.config/rclone-jobman"
    
function usage() {            # Intended usage
    echo "Usage: $scriptName (with no arguments)"
}

function exitBadUsage() {     # exit code 1
    usage; exit 1;
}

function pressAnyKey() {
    read -rsn 1 -p "Press any key to continue." && echo ""
}

function askConfirmation() {  # exit code 2
    local userInput
    read -r -p "Type YES to confirm: " userInput
    case $userInput in
        YES) return 0;;
        *) echo "Process interrupted by the user."; exit 2;;
    esac
}

function promptIfFileExists() {
    test ! -f "$1" && return 0
    echo "WARNING: file $1 already exists. Do you want to overwrite it?"
    askConfirmation
}

function createNewJob() {
    local jobBasename jobName dryrun sourcePath destinationPath

    echo "Please input the following settings:"

    # Ask for filename. Ask if any file exists.
    read -r -p "Base filename: " jobBasename
    local jobFile="$confPath/jobs/$jobBasename";                      promptIfFileExists "$jobFile"
    local filterfromFile="$confPath/filter-from/$jobBasename.filter"; promptIfFileExists "$filterfromFile"
    local lockFile="$confPath/lock/$jobBasename.lock";                promptIfFileExists "$lockFile"
    local logFile="$confPath/log/$jobBasename.log";                   promptIfFileExists "$logFile"

    # Ask for the settings
    read -r -p "Descriptive name: " jobName
    read -r -p "Source path: "      sourcePath
    read -r -p "Destinatino path: " destinationPath
    dryrun=TRUE # Should ask user?

    # Ask for confirmation
    echo "Is this correct?"
    echo "File name:        $jobBasename"
    echo "Descriptive name: $jobName"
    echo "Source path:      $sourcePath"
    echo "Destination path: $destinationPath"
    echo "--dry-run option: $dryrun (for now, this is set to TRUE by default.)" # Remove text if this changes
    askConfirmation

    # Create file or empty them
    cat /dev/null > "$jobFile"
    cat /dev/null > "$filterfromFile"
    cat /dev/null > "$lockFile"
    [[ -f "$logFile" ]] && rm "$logFile"  # Remove log file so menu says it has never been run.
    # Write the $jobFile
    {   echo "# Descriptive name for the sync job"
        echo "jobName=$jobName"
        echo "# For testing purposes, set to TRUE and rclone will NOT write anything to the remote server."
        echo "dryrun=$dryrun"
        echo "# Paths for source (READ) and destination (WRITE)"
        echo "sourcePath=$sourcePath"
        echo "destinationPath=$destinationPath" 
    } >> "$jobFile"
    # Write the $filterfromFile and open with default editor
    {   echo "# This is the filter-from file for the job $jobFile."
        echo "# Check out https://rclone.org/filtering/#filter-from-read-filtering-patterns-from-a-file for reference."
    } >> "$filterfromFile"
    echo "I will now open the file $filterfromFile so you can edit it."
    pressAnyKey
    /usr/bin/env editor "$filterfromFile"

    exit 0
}

if [[ $# -eq 0 ]]; then createNewJob; else exitBadUsage; fi