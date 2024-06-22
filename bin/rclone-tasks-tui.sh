#!/usr/bin/env bash

###################################################################
# Script Name : rclone-tasks-tui.sh
# Description : Simple task manager for rclone running syncs.
#               This script opens a simple TUI to run and manage tasks.
# Args        : [None]
# Author      : CarlesCN
# E-mail      : carlesbioinformatics@gmail.com
# License     : GNU General Public License v3.0
###################################################################

# -e script ends on error (exit != 0)
# -u error if undefined variable
# -o pipefail script ends if piped command fails
set -euo pipefail

# Set some paths
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_DIR="$HOME/.config/rclone-jobman/log"
LOCK_DIR="$HOME/.config/rclone-jobman/lock"
TASKS_DIR="$HOME/.config/rclone-jobman/jobs"

# Set some constants
SCRIPT_NAME='rclone-jobman'
BOX_WIDTH=100

source "$SCRIPT_DIR/rclone-jobman_submenus.sh"
source "$SCRIPT_DIR/rclone-jobman_newjob.sh"
source "$SCRIPT_DIR/utils.sh"


function call_rclone { # $1=task file
    /usr/bin/env bash -c "$SCRIPT_DIR/rclone-tasks-runner.sh $(realpath "$1")"
}


function time_since_file_modified {
    local file=$1
    [[ ! -f "$file" ]] && echo "NEVER!" && return 0
    local seconds; seconds=$(("$(date -u +%s)" - "$(date -ur "$file" +%s)"))
    echo "$((seconds/3600/24)) days and $((seconds/3600%24)) hours"
}


while true; do
    # Get all the files in the jobs folder
    mapfile -t files_array < <(ls -d "$TASKS_DIR"/*)

    # Set the menu entries
    menu_entries=()
    for index in "${!files_array[@]}"; do
        task_file="${files_array[$index]}"
        task_name=$(get_value_from_file "$task_file" name)
        log_file="$LOG_DIR/$(basename "$task_file").log"
        last_sync=$(time_since_file_modified "$log_file")
        menu_entries+=("$index" "  Run task $task_name [last sync: $last_sync]")
    done
    menu_entries+=(" " "") # Blank line to separate the task from the menu options
    menu_entries+=("N" "  create New task")
    menu_entries+=("E" "  Edit task")
    menu_entries+=("R" "  Remove task")
    menu_entries+=("L" "  read Log file")

    # Build the menu
    menu_height=$(( "${#menu_entries[@]}" / 2))
    box_height=$(( 8 + "$menu_height"))
    menu_out=$(whiptail --backtitle "$SCRIPT_NAME" --title "MAIN MENU" \
        --menu "Choose one option:" \
        "$box_height" "$BOX_WIDTH" "$menu_height" "${menu_entries[@]}" --cancel-button "Exit"\
        3>&1 1>&2 2>&3) || exit 0  # Cancel button returns 1 and makes the script exit with non-zero code

    # Manage the output
    [[ -z "$menu_out" ]] && exit 4  # Should not happen (already have returned 0 if user pressed Cancel)
    case "$menu_out" in
        [0-$index]) call_rclone "${files_array[$menu_out]}" || continue;;
        N)          create_new_job || continue ;;
        E)          submenu edit_job   "EDIT TASK"   ;;
        R)          submenu remove_job "REMOVE TASK" ;;
        L)          submenu show_log   "SHOW LOG"   ;;
        *)          continue  ;;
    esac
done
