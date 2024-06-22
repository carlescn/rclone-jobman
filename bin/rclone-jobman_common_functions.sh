#!/usr/bin/env bash

###################################################################
# Library Name : rclone-jobman.sh
# Description  : This library is part of rclone-jobman.
#                It contains common functions.
#                See main script for author, license and contact info.
###################################################################

function exit_if_file_missing() {  # EXIT CODE 2
    if [[ ! -f "$1" ]]; then
        error_box "ERROR: Could not find file $1."
        exit 2
    fi
}

function message_box() {
    local IFS=; local message="$*"
    local box_height=$(( 6 + $# ))
    whiptail --backtitle "${SCRIPT_NAME:?}" --msgbox "$message" "$box_height" "${BOX_WIDTH:?}"
}

function error_box() {
    local IFS=; local message="$*"
    local box_height=$(( 6 + $# ))
    whiptail --backtitle "${SCRIPT_NAME:?}" --title "ERROR" --msgbox "$message" "$box_height" "${BOX_WIDTH:?}"
    echo "$message" >&2
}

function ask_for_confirmation() {
# Asks user for confirmation. Returns 1 if response is NO.
    local IFS=; local message="$*"
    local box_height=$(( 6 + $# ))
    local title="Please confirm"
    if whiptail --backtitle "${SCRIPT_NAME:?}" --title "$title" --yesno "$message" "$box_height" "${BOX_WIDTH:?}" --defaultno; then
        return 0
    else
        message_box "Process interrupted by the user. Returning to the menu..."
        return 1
    fi
}

function yes_no_dialog() {
    local IFS=; local message="$*"
    local box_height=$(( 6 + $# ))
    if whiptail --backtitle "${SCRIPT_NAME:?}" --title "Please confirm" --yesno "$message" "$box_height" "${BOX_WIDTH:?}" --defaultno; then
        return 0
    else
        return 1
    fi
}