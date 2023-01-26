#!/usr/bin/env bash

###################################################################
#Script Name : rclone-jobman-editjob.sh
#Description : For use with rclone-jobman.sh. Edits a job.
#Args        : -
#Author      : CarlesCN
#E-mail      : drtlof@gmail.com
###################################################################

# -e script ends on error (exit != 0)
# -u error if undefined variable
# -o pipefail script ends if piped command fails
set -euo pipefail

readonly scriptName="rclone-jobman-editjob.sh"
readonly confPath="$HOME/.config/rclone-jobman"

function usage() {            # Intended usage:
    echo "Usage: $scriptName (with no arguments)"
}

function exitBadUsage() {     # exit code 1
    usage; exit 1;
}

function exitIfFileMissing() {  # exit code 2
    if [[ ! -f "$1" ]]; then
        echo "ERROR: Could not find file \"$1\"." >&2
        exit 2
    fi
}

function exitMissingKey() {     # exit code 3
    echo "ERROR: Key \"$1\" is missing in your configuration file, or it is empty." >&2
    exit 3
}

function pressAnyKey() {
    read -rsn 1 -p "Press any key to continue." && echo ""
}

function readJobFileLine() {
    local file=$1
    local key=$2
    local value; value=$(grep "$key" "$file" | cut --fields=2 --delimiter="=")
    test -z "$value" && exitMissingKey "$key"
    echo "$value"
}

function editJob() {
    local jobFile=$1
    local jobBasename; jobBasename=$(basename "$jobFile");            exitIfFileMissing "$jobFile"
    local filterfromFile="$confPath/filter-from/$jobBasename.filter"; exitIfFileMissing "$filterfromFile"

    echo "Opening file $jobFile with your default text editor."
    pressAnyKey
    /usr/bin/env editor "$jobFile"

    echo "Opening file $filterfromFile with your default text editor."
    pressAnyKey
    /usr/bin/env editor "$filterfromFile"

    echo -e "Done! \n"
}

function main() {
    local filesArray jobFile jobName userInput
    # Get all the files in the jobs folder
    mapfile -t filesArray < <(ls -d "$confPath"/jobs/*)

    while true; do
        # Print the menu
        echo "List of available jobs:"
        for idx in "${!filesArray[@]}"; do
            jobFile=${filesArray[$idx]}
            jobName=$(readJobFileLine "$jobFile" jobName)
            echo "$idx) $jobName"
        done
        echo "r|q) Return to main menu."
        
        # Read the user input
        read -r -p "Choose one job to edit: " userInput; echo""
        case $userInput in
            [0-$idx]) editJob "$(realpath "${filesArray[$userInput]}")" ;;
            r|R|q|Q)      break ;;
            *)        echo -e "Invalid option, try again! \n" ;;
        esac
    done

    exit 0
}

if [[ $# -eq 0 ]]; then main; else exitBadUsage; fi