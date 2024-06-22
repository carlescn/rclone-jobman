#!/usr/bin/env bash

###############################################################################
# [rclone-tasks-tui-newtask.sh]
# This library is part of rclone-tasks TUI.
# It contains the logic to create a new task.
# See main script for author, license and contact info.
###############################################################################

function prompt_if_file_exists() {
    [[ -f "$1" ]] || return 0
    local message=("The file $1 already exists. \n")
    message+=("Do you want to OVERWRITE it? \n")
    message+=("\n" "WARNING: This operation is IRREVERSIBLE.") # two items so ask_for_confirmation draws the proper height
    ask_for_confirmation "${message[@]}" || return 1
}

function read_input_text() {
    local message; message=$1  # Declare and assign separately because ShellCheck gets confused (SC2178)
    local user_input
    while true; do
        user_input=$(whiptail --backtitle "${SCRIPT_NAME:?}" --title "NEW TASK" \
            --inputbox "$message" 8 "${BOX_WIDTH:?}" \
            3>&1 1>&2 2>&3) || return 1  # Return 1 if user pressed Cancel.
        [[ -n $user_input ]] && echo "$user_input" && return 0
        message_box "The field can't be empty!" >&2
    done
}

function create_new_task() {
    local task_basename task_name dry_run source_path destination_path

    task_basename=$(read_input_text "(1/4) Please enter the new UNIQUE task name:") || return 1

    local task_file="$RCLONETASKS_TASKS_PATH/$task_basename.toml";
    local lock_file="$RCLONETASKS_LOCK_PATH/$task_basename.lock";
    local log_file="$RCLONETASKS_LOG_PATH/$task_basename.log";
    prompt_if_file_exists "$task_file"  || return 2
    prompt_if_file_exists "$lock_file" || return 2
    prompt_if_file_exists "$log_file"  || return 2

    task_name=$(read_input_text "(2/4) Please enter a DESCRIPTIVE name:") || return 1
    source_path=$(read_input_text "(3/4) Please the SOURCE path (where to read from):") || return 1
    destination_path=$(read_input_text "(4/4) Please enter the DESTINATION path (where to write to):") || return 1
    
    local dry_run_message="Dry-run is set to TRUE by default. You can set it to FALSE now or edit the file later."
    if whiptail --backtitle "${SCRIPT_NAME:?}" --title "NEW TASK" --yesno "$dry_run_message" 10 "${BOX_WIDTH:?}" --yes-button "TRUE" --no-button "FALSE"; then
        dry_run=true
    else
        dry_run=false
    fi

    local message=()
    message+=("Is this correct? \n")
    message+=("File name:        $task_basename \n")
    message+=("Descriptive name: $task_name \n")
    message+=("Source path:      $source_path \n")
    message+=("Destination path: $destination_path \n")
    message+=("--dry-run option: $dry_run")
    ask_for_confirmation "${message[@]}"  || return 1

    # Write the $task_file
    {   echo "[task]"
        echo "name = \"$task_name\""
        echo "dry_run = $dry_run"
        echo ""
        echo "[paths]"
        echo "source      = \"$source_path\""
        echo "destination = \"$destination_path\""
        echo ""
        echo "[filter]"
        echo "# Check out https://rclone.org/filtering/#filter-add-a-file-filtering-rule for reference."
        echo "# every string in this array will added to the rclone arguments as '--filter string'"
        echo "rules = []"
    } > "$task_file"

    # Remove and recreate $lock_file to ensure proper ownership (user:group)
    [[ -f "$lock_file" ]] && rm "$lock_file"
    touch "$lock_file"

    # Remove log file so menu says it has never been run.
    [[ -f "$log_file" ]] && rm "$log_file"

    yes_no_dialog "Open file $task_file to edit the filter rules?" || return 0
    $EDITOR "$task_file"

    message_box "Finished creating task $task_basename!"
}
