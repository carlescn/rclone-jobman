#!/usr/bin/env bash

###################################################################
# Library Name : rclone-jobman.sh
# Description  : This library is part of rclone-jobman.
#                It contains functions to create a new job.
#                See main script for author, license and contact info.
###################################################################

function prompt_if_file_exists() {
    [[ -f "$1" ]] || return 0
    echo "WARNING: file $1 already exists. Do you want to overwrite it?"
    ask_for_confirmation || return $?
}

function create_new_job() {
    local job_basename job_name dry_run source_path destination_path

    echo "rclone-jobman: NEW JOB"
    echo "Please input the following fields:"

    read -r -p "New job filename: " job_basename
    [[ -z $job_basename ]] && echo "Field cannot be empty!" && return 1

    local job_file="${conf_path:?}/jobs/$job_basename";
    local filterfrom_file="$conf_path/filterfrom/$job_basename.filter";
    local lock_file="$conf_path/lock/$job_basename.lock";
    local log_file="$conf_path/log/$job_basename.log";
    prompt_if_file_exists "$job_file"        || return 0
    prompt_if_file_exists "$filterfrom_file" || return 0
    prompt_if_file_exists "$lock_file"       || return 0
    prompt_if_file_exists "$log_file"        || return 0

    read -r -p "Descriptive name: "  job_name
    [[ -z $job_name ]] && echo "Field cannot be empty!" && return 1
    read -er -p "Source path: "      source_path
    [[ -z $source_path ]] && echo "Field cannot be empty!" && return 1
    read -er -p "Destinatino path: " destination_path
    [[ -z $destination_path ]] && echo "Field cannot be empty!" && return 1
    echo "Dry-run is set to TRUE by default. You can set it to FALSE now or edit it later. "
    read -r -p "Type FALSE to set dry_run to FALSE: " dry_run
    [[ "$dry_run" == "FALSE" ]] || dry_run="TRUE"

    echo "Is this correct?"
    echo "File name:        $job_basename"
    echo "Descriptive name: $job_name"
    echo "Source path:      $source_path"
    echo "Destination path: $destination_path"
    echo "--dry-run option: $dry_run"
    ask_for_confirmation || return 0

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
    echo "I will now open the file $filterfrom_file so you can edit it."
    press_any_key || return 0
    /usr/bin/env editor "$filterfrom_file"
}