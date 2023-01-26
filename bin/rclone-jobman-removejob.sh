#!/usr/bin/env bash

###################################################################
#Script Name : rclone-jobman-removejob.sh
#Description : For use with rclone-jobman.sh. Removes a job.
#Args        : -
#Author      : CarlesCN
#E-mail      : drtlof@gmail.com
###################################################################

# -e script ends on error (exit != 0)
# -u error if undefined variable
# -o pipefail script ends if piped command fails
set -euo pipefail

readonly scriptName="rclone-jobman-removejob.sh"
readonly confPath="$HOME/.config/rclone-jobman"

function usage() {              # Intended usage:
    echo "Usage: $scriptName (with no arguments)"
}

function exitBadUsage() {       # exit code 1
    usage; exit 1;
}

function exitMissingKey() {     # exit code 3
    echo "ERROR: Key \"$1\" is missing in your configuration file, or it is empty." >&2
    exit 3
}

function readJobFileLine() {
    local file=$1
    local key=$2
    local value; value=$(grep "$key" "$file" | cut --fields=2 --delimiter="=")
    [[ -z "$value" ]] && exitMissingKey "$key"
    echo "$value"
}

function askConfirmation() {  # exit code 2
    local userInput
    read -r -p "Type YES to confirm: " userInput
    case $userInput in
        YES) return 0;;
        *) echo "Process interrupted by the user."; exit 2;;
    esac
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
    askConfirmation

    rm "${filesToRemove[@]}"

    exit 0
}

function main() {
    local filesArray jobFile jobName userInput idx
    # Get all the files in the jobs folder
    mapfile -t filesArray < <(ls -d "$confPath"/jobs/*)

    while true; do
        # Print the menu
        echo "rclone-jobman: REMOVE JOB"
        for idx in "${!filesArray[@]}"; do
            jobFile=${filesArray[$idx]}
            jobName=$(readJobFileLine "$jobFile" jobName)
            echo "$idx) $jobName"
        done
        echo "r|q) Return to main menu."
        
        # Read the user input
        read -r -p "Choose one option: " userInput; echo""
        case $userInput in
            [0-$idx]) removeJob "$(realpath "${filesArray[$userInput]}")" ;;
            r|R|q|Q)  break ;;
            *)        echo -e "Invalid option, try again! \n" ;;
        esac
    done

    exit 0
}

if [[ $# -eq 0 ]]; then main; else exitBadUsage; fi