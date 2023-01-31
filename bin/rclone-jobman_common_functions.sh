#!/usr/bin/env bash

###################################################################
# Library Name : rclone-jobman.sh
# Description  : This library is part of rclone-jobman.
#                It contains common functions.
#                See main script for author, license and contact info.
###################################################################

function exit_bad_usage() {                   # exit code 1
    usage
    exit 1
}

function exit_if_file_missing() {             # exit code 2
    if [[ ! -f "$1" ]]; then
        echo "ERROR: Could not find file $1." >&2
        exit 2
    fi
}

function exit_on_read_job_file_line_fail() {  # exit code 3
    echo "ERROR: Key $1 is missing in your configuration file, or it is empty." >&2
    exit 3
}

function read_job_file_line() {
# Tries to read key & value pair from job file
    local file=$1
    local key=$2
    local value; value=$(grep "$key" "$file" | cut --fields=2 --delimiter="=")
    [[ -z "$value" ]] && exit_on_read_job_file_line_fail "$key"
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