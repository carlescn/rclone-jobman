#!/usr/bin/env bash

###################################################################
#Script Name : rclone-jobman-showlog.sh
#Description : For use with rclone-jobman.sh. Shows the last log of a job.
#Args        : -
#Author      : CarlesCN
#E-mail      : drtlof@gmail.com
###################################################################

# -e script ends on error (exit != 0)
# -u error if undefined variable
# -o pipefail script ends if piped command fails
set -euo pipefail

readonly scriptName="rclone-jobman-showlog.sh"
readonly confPath="$HOME/.config/rclone-jobman"

function usage() {              # Intended usage:
    echo "Usage: $scriptName (with no arguments)"
}

function exitBadUsage() {       # exit code 1
    usage; exit 1;
}

function exitMissingKey() {     # exit code 3 (not 2 for consistency with the rest of scripts)
    echo "ERROR: Key \"$1\" is missing in your configuration file, or it is empty." >&2
    exit 3
}

function readJobFileLine() {
    local file=$1
    local key=$2
    local value; value=$(grep "$key" "$file" | cut --fields=2 --delimiter="=")
    test -z "$value" && exitMissingKey "$key"
    echo "$value"
}

function main() {
    local filesArray jobFile jobName logFiles userInput idx
    # Get all the files in the jobs folder
    mapfile -t filesArray < <(ls -d "$confPath"/jobs/*)

    while true; do        
        # Print the menu
        echo "rclone-jobman: SHOW LOG"
        local logFiles=()
        for idx in "${!filesArray[@]}"; do
            jobFile=${filesArray[$idx]};
            jobName=$(readJobFileLine "$jobFile" jobName)
            logFiles+=("$confPath/log/$(basename "$jobFile").log")
            echo "$idx) $jobName"
        done
        echo "r|q) Return to main menu."

        # Read the user input
        read -r -p "Choose one option: " userInput; echo ""
        case $userInput in
            [0-$idx]) [[ -f ${logFiles[$userInput]} ]] && more "${logFiles[$userInput]}" ;;
            r|R|q|Q)  break ;;
            *)        echo -e "Invalid option, try again! \n" ;;
        esac
    done
}

if [[ $# -eq 0 ]]; then main; else exitBadUsage; fi