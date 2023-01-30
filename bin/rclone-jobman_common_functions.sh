#!/usr/bin/env bash

###################################################################
# Library Name : rclone-jobman.sh
# Description  : This library is part of rclone-jobman.
#                It contains common functions.
#                See main script for author and contact info.
###################################################################

function exitBadUsage() {               # exit code 1
    usage
    exit 1
}

function exitIfFileMissing() {          # exit code 2
    if [[ ! -f "$1" ]]; then
        echo "ERROR: Could not find file $1." >&2
        exit 2
    fi
}

function exitReadJobFileLineFailed() {  # exit code 3
    echo "ERROR: Key $1 is missing in your configuration file, or it is empty." >&2
    exit 3
}

function readJobFileLine() {
# Tries to read key & value pair from job file
    local file=$1
    local key=$2
    local value; value=$(grep "$key" "$file" | cut --fields=2 --delimiter="=")
    [[ -z "$value" ]] && exitReadJobFileLineFailed "$key"
    echo "$value"
}

function askConfirmation() {
# Asks user to type YES or returns 1
    local userInput
    read -r -p "Type YES to confirm: " userInput
    if [[ $userInput != YES ]]; then
        echo -e "Process interrupted by the user."
        return 1
    fi
}

function pressAnyKey() {
    local userInput
    read -rsn 1 -p "Press C to cancel, or any key to continue." userInput && echo ""
    case $userInput in
        c|C)  return 1 ;;
        *)    return 0 ;;
    esac
}