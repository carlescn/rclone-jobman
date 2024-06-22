#!/usr/bin/env bash

###################################################################
# Library Name : rclone-jobman.sh
# Description  : This library is part of rclone-jobman.
#                It contains functions to create a new job.
#                See main script for author, license and contact info.
###################################################################

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
        user_input=$(whiptail --backtitle "${SCRIPT_NAME:?}" --title "NEW JOB" \
            --inputbox "$message" 8 "${BOX_WIDTH:?}" \
            3>&1 1>&2 2>&3) || return 1  # Return 1 if user pressed Cancel.
        [[ -n $user_input ]] && echo "$user_input" && return 0
        message_box "The field can't be empty!" >&2
    done
}

function create_new_job() {
    local job_basename job_name dry_run source_path destination_path

    job_basename=$(read_input_text "(1/4) Please enter the new UNIQUE job name:") || return 1

    local job_file="$TASKS_DIR/$job_basename";
    local filterfrom_file="$TASKS_DIR/$job_basename.filter";
    local lock_file="$LOCK_DIR/$job_basename.lock";
    local log_file="$LOG_DIR/$job_basename.log";
    prompt_if_file_exists "$job_file"        || return 2
    prompt_if_file_exists "$filterfrom_file" || return 2
    prompt_if_file_exists "$lock_file"       || return 2
    prompt_if_file_exists "$log_file"        || return 2

    job_name=$(read_input_text "(2/4) Please enter a DESCRIPTIVE name:") || return 1
    source_path=$(read_input_text "(3/4) Please the SOURCE path (where to read from):") || return 1
    destination_path=$(read_input_text "(4/4) Please enter the DESTINATION path (where to write to):") || return 1
    
    local dry_run_message="Dry-run is set to TRUE by default. You can set it to FALSE now or edit it later."
    if whiptail --backtitle "${SCRIPT_NAME:?}" --title "NEW JOB" --yesno "$dry_run_message" 10 "${BOX_WIDTH:?}" --defaultno --yes-button "TRUE" --no-button "FALSE"; then
        dry_run="TRUE"
    else
        dry_run="FALSE"
    fi

    local message=()
    message+=("Is this correct? \n")
    message+=("File name:        $job_basename \n")
    message+=("Descriptive name: $job_name \n")
    message+=("Source path:      $source_path \n")
    message+=("Destination path: $destination_path \n")
    message+=("--dry-run option: $dry_run")
    ask_for_confirmation "${message[@]}"  || return 1

    # Write the $job_file
    {   echo "# Descriptive name for the sync job"
        echo "job_name=$job_name"
        echo "# For testing purposes, set to TRUE and rclone will NOT write anything to the remote server."
        echo "dry_run=$dry_run"
        echo "# Paths for source (READ) and destination (WRITE)"
        echo "source_path=$source_path"
        echo "destination_path=$destination_path"
    } > "$job_file"

    # Remove and recreate $lock_file to ensure proper ownership (user:group)
    [[ -f "$lock_file" ]] && rm "$lock_file"
    touch "$lock_file"

    # Remove log file so menu says it has never been run.
    [[ -f "$log_file" ]] && rm "$log_file"

    # Write the $filterfrom_file and open with default editor
    {   echo "# This is the filter-from file for the job $job_file."
        echo "# Check out https://rclone.org/filtering/#filter-from-read-filtering-patterns-from-a-file for reference."
    } > "$filterfrom_file"
    local message2="Open file $filterfrom_file to edit it?"
    yes_no_dialog "$message2" || return 0
    $EDITOR "$filterfrom_file"

    message_box "Finished creating job $job_basename!"
}