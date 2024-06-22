#!/usr/bin/env bash

###############################################################################
# [rclone-tasks-tui-submenus.sh]
# This library is part of rclone-tasks TUI.
# It contains the logic to run the submenus options.
# See main script for author, license and contact info.
###############################################################################

function submenu() {
    local call_function=$1
    local name_function=$2
    local files_array task_file task_name index
    while true; do
        # Get all the files in tasks folder
        mapfile -t files_array < <(ls -d "$RCLONETASKS_TASKS_PATH"/*)
        
        # Set the menu entries
        local menu_entries=()
        for index in "${!files_array[@]}"; do
            task_file="${files_array[$index]}"
            task_name=$(yq -oy '.task.name' "$task_file")
            menu_entries+=("$index" "$task_name")
        done

        # Build the menu
        local menu_height="${#files_array[@]}"
        local box_height=$(( 8 + "$menu_height"))
        local menu_out
        menu_out=$(whiptail --backtitle "${SCRIPT_NAME:?}" --title "$name_function" \
            --menu "Choose a task:" "$box_height" "${BOX_WIDTH:?}" "$menu_height" "${menu_entries[@]}" \
            3>&1 1>&2 2>&3) || return 0  # Cancel button returns 1 and makes this script exit with non-zero code
        
        # Manage the output
        [[ -z "$menu_out" ]] && return 1  # Should not happen (already have returned 0 if user pressed Cancel)
        "$call_function" "$(realpath "${files_array[$menu_out]}")"
    done
}

function edit_task() {
    local task_file=$1
    local task_basename; task_basename=$(basename "$task_file" .toml)
    exit_if_file_missing "$task_file"

    local message="Open file $task_file to edit it?"
    yes_no_dialog "$message" && $EDITOR "$task_file"

    message_box "Finished editing task $task_basename!"
}

function remove_task() {
    local task_file=$1
    local task_basename; task_basename=$(basename "$task_file" .toml)
    local lock_file="$RCLONETASKS_LOCK_PATH/$task_basename.lock"
    local log_file="$RCLONETASKS_LOG_PATH/$task_basename.log"

    local files_to_remove=()
    [[ -f $task_file ]]  && files_to_remove+=("$task_file")
    [[ -f $lock_file ]] && files_to_remove+=("$lock_file")
    [[ -f $log_file ]]  && files_to_remove+=("$log_file")
   
    local message=()
    message+=("The following files will be permanently REMOVED: \n")
    local file
    for file in "${files_to_remove[@]}"; do
        message+=("- $file \n")
    done
    message+=("\n" "WARNING: This operation is IRREVERSIBLE.") # two items so ask_for_confirmation draws the proper height
    ask_for_confirmation "${message[@]}" || return 0

    rm "${files_to_remove[@]}"

    message_box "Task $task_basename removed!"
}

function show_log() {
    local task_file=$1
    local base_name; base_name=$(basename "$task_file" .toml)
    local log_file; log_file="$RCLONETASKS_LOG_PATH/$base_name.log"
    if [[ -f $log_file ]]; then
        # shellcheck disable=SC2046  # $(stty size) outputs full screen height and width
        whiptail --backtitle "${SCRIPT_NAME:?}" --title "$log_file" --textbox "$log_file" $(stty size) --scrolltext
    else
        error_box "ERROR: Could not find file $log_file."
    fi
}