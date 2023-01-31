#!/usr/bin/env bash

###################################################################
# Library Name : rclone-jobman.sh
# Description  : This library is part of rclone-jobman.
#                It contains common functions.
#                See main script for author, license and contact info.
###################################################################

function exit_bad_usage() {        # EXIT CODE 1
    usage
    exit 1
}

function exit_if_file_missing() {  # EXIT CODE 2
    if [[ ! -f "$1" ]]; then
        echo "ERROR: Could not find file $1." >&2
        exit 2
    fi
}

function read_job_file_line() {    # EXIT CODE 3
# Tries to read key & value pair from job file. Exits on error.
# Locates the first line that begins with key and gets the first word after the '=' sign.
# Can't handle spaces next to the '=' sign.
# Discards any text to the right of value (after a space).
    local file=$1
    local key=$2
    local value; value=$(awk -F'[= ]' '/^'"$key"'/ {print $2; exit}' "$file" )
    if [[ -z "$value" ]]; then
        echo "ERROR: Key $key is missing in your configuration file, or it is empty." >&2
        exit 3
    fi
    echo "$value"
}

function ask_for_confirmation() {
# Asks user to type YES or returns 1
    local user_input
    read -r -p "Type YES to confirm: " user_input
    if [[ $user_input != YES ]]; then
        echo -e "Process interrupted by the user."
        return 1
    fi
}

function press_any_key() {
    local user_input
    read -rsn 1 -p "Press C to cancel, or any key to continue." user_input && echo ""
    case $user_input in
        c|C)  return 1 ;;
        *)    return 0 ;;
    esac
}