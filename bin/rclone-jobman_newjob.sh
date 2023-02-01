#!/usr/bin/env bash

###################################################################
# Library Name : rclone-jobman.sh
# Description  : This library is part of rclone-jobman.
#                It contains functions to create a new job.
#                See main script for author, license and contact info.
###################################################################

function prompt_if_file_exists() {
    [[ -f "$1" ]] || return 0
    local message=("WARNING: file $1 already exists. \n" "Do you want to overwrite it?")
    ask_for_confirmation "${message[@]}" || return 1
}

function create_new_job() {
    local job_basename job_name dry_run source_path destination_path

    echo "rclone-jobman: NEW JOB"
    echo "Please input the following fields:"

    read -r -p "New job filename: " job_basename
    [[ -z $job_basename ]] && echo "Field cannot be empty!" && return 2

    local job_file="${conf_path:?}/jobs/$job_basename";
    local filterfrom_file="$conf_path/filterfrom/$job_basename.filter";
    local lock_file="$conf_path/lock/$job_basename.lock";
    local log_file="$conf_path/log/$job_basename.log";
    prompt_if_file_exists "$job_file"        || return 3
    prompt_if_file_exists "$filterfrom_file" || return 3
    prompt_if_file_exists "$lock_file"       || return 3
    prompt_if_file_exists "$log_file"        || return 3

    read -r -p "Descriptive name: "  job_name
    [[ -z $job_name ]] && echo "Field cannot be empty!" && return 4
    read -er -p "Source path: "      source_path
    [[ -z $source_path ]] && echo "Field cannot be empty!" && return 4
    read -er -p "Destinatino path: " destination_path
    [[ -z $destination_path ]] && echo "Field cannot be empty!" && return 4
    echo "Dry-run is set to TRUE by default. You can set it to FALSE now or edit it later. "
    read -r -p "Type FALSE to set dry_run to FALSE: " dry_run
    [[ "$dry_run" == "FALSE" ]] || dry_run="TRUE"

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
    /usr/bin/env editor "$filterfrom_file"

    message_box "Finished creating job $job_basename!"
}