#!/usr/bin/env bash

###################################################################
# Library Name : rclone-jobman.sh
# Description  : This library is part of rclone-jobman.
#                It contains functions to run the submenus options.
#                See main script for author and contact info.
###################################################################

function submenu() {
    local callFunction=$1
    local nameFunction=$2
    local filesArray jobFile jobName userInput idx 
    while true; do
        # Get all the files in the jobs folder
        mapfile -t filesArray < <(ls -d "${confPath:?}"/jobs/*)
        
        # Print the menu
        echo "" # Blank line for clearer presentation
        echo "rclone-jobman - $nameFunction:"
        for idx in "${!filesArray[@]}"; do
            jobFile=${filesArray[$idx]}
            jobName=$(readJobFileLine "$jobFile" jobName)
            echo "$idx) $jobName"
        done
        echo "-----------------------"
        echo "q) Return to main menu."
        
        # Read the user input
        read -r -p "Choose one option: " userInput; echo""
        case $userInput in
            [0-$idx])  "$callFunction" "$(realpath "${filesArray[$userInput]}")" ;;
            q|Q)       return 0 ;;
            *)         echo "Invalid option, try again!" ;;
        esac
    done
}

function editJob() {
    local jobFile=$1
    local jobBasename; jobBasename=$(basename "$jobFile");            exitIfFileMissing "$jobFile"
    local filterfromFile="$confPath/filter-from/$jobBasename.filter"; exitIfFileMissing "$filterfromFile"

    echo "Opening file $jobFile with your default text editor."
    pressAnyKey && /usr/bin/env editor "$jobFile"

    echo "Opening file $filterfromFile with your default text editor."
    pressAnyKey && /usr/bin/env editor "$filterfromFile"

    echo "Done!"
}

function removeJob() {
    local jobFile=$1
    local jobBasename; jobBasename=$(basename "$jobFile")
    local filterfromFile="$confPath/filter-from/$jobBasename.filter"
    local lockFile="$confPath/lock/$jobBasename.lock"
    local logFile="$confPath/log/$jobBasename.log"

    local filesToRemove=()
    [[ -f $jobFile ]]        && filesToRemove+=("$jobFile")
    [[ -f $filterfromFile ]] && filesToRemove+=("$filterfromFile")
    [[ -f $lockFile ]]       && filesToRemove+=("$lockFile")
    [[ -f $logFile ]]        && filesToRemove+=("$logFile")
   
    echo "This will remove the following files:"
    local file
    for file in "${filesToRemove[@]}"; do
        echo "  $file"
    done
    echo "This operation is irreversible. Are you sure?"
    askConfirmation || return 0

    rm "${filesToRemove[@]}"
}

function showLog() {
    local jobFile=$1
    local logFile; logFile="$confPath/log/$(basename "$jobFile").log"
    if [[ -f $logFile ]]; then
        echo "[BEGIN $logFile]"
        more "$logFile"
        echo "[END $logFile]"
    else
        echo "ERROR: Could not find file $logFile." >&2
    fi
}