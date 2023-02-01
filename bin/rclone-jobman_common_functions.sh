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
        error_box "ERROR: Could not find file $1."
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
        error_box "ERROR: Key $key is missing in your configuration file, or it is empty."
        exit 3
    fi
    echo "$value"
}

function message_box() {
    local IFS=; local message="$*"
    local box_height=$(( 6 + $# ))
    whiptail --backtitle "${script_name:?}" --msgbox "$message" "$box_height" "${box_width:?}"
}

function error_box() {
    local IFS=; local message="$*"
    local box_height=$(( 6 + $# ))
    whiptail --backtitle "${script_name:?}" --title "ERROR" --msgbox "$message" "$box_height" "${box_width:?}"
    echo "$message" >&2
}

function ask_for_confirmation() {
# Asks user for confirmation. Returns 1 if response is NO.
    local IFS=; local message="$*"
    local box_height=$(( 6 + $# ))
    local title="This operation is IRREVERSIBLE. Are you sure?"
    if whiptail --backtitle "${script_name:?}" --title "$title" --yesno "$message" "$box_height" "${box_width:?}" --defaultno; then
        return 0
    else
        message_box "Process interrupted by the user. Returning to the menu..."
        return 1
    fi
}

function yes_no_dialog() {
    local IFS=; local message="$*"
    local box_height=$(( 6 + $# ))
    if whiptail --backtitle "${script_name:?}" --title "Please confirm" --yesno "$message" "$box_height" "${box_width:?}" --defaultno; then
        return 0
    else
        return 1
    fi
}