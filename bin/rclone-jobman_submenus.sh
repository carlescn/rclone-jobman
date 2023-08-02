#!/usr/bin/env bash

###################################################################
# Library Name : rclone-jobman.sh
# Description  : This library is part of rclone-jobman.
#                It contains functions to run the submenus options.
#                See main script for author, license and contact info.
###################################################################

function submenu() {
    local call_function=$1
    local name_function=$2
    local files_array job_file job_name index
    while true; do
        # Get all the files in the jobs folder
        mapfile -t files_array < <(ls -d "${conf_path:?}"/jobs/*)
        
        # Set the menu entries
        local menu_entries=()
        for index in "${!files_array[@]}"; do
            job_file="${files_array[$index]}"
            job_name=$(read_job_file_line "$job_file" job_name)
            menu_entries+=("$index" "$job_name")
        done

        # Build the menu
        local menu_height="${#files_array[@]}"
        local box_height=$(( 8 + "$menu_height"))
        local menu_out
        menu_out=$(whiptail --backtitle "${script_name:?}" --title "$name_function" \
            --menu "Choose a job:" "$box_height" "${box_width:?}" "$menu_height" "${menu_entries[@]}" \
            3>&1 1>&2 2>&3) || return 0  # Cancel button returns 1 and makes this cript exit with non-zero code
        
        # Manage the output
        [[ -z "$menu_out" ]] && return 1  # Should not happen (already have returned 0 if user pressed Cancel)
        "$call_function" "$(realpath "${files_array[$menu_out]}")"
    done
}

function edit_job() {
    local job_file=$1
    local job_basename; job_basename=$(basename "$job_file");           exit_if_file_missing "$job_file"
    local filterfrom_file="$conf_path/filterfrom/$job_basename.filter"; exit_if_file_missing "$filterfrom_file"

    local message="Open file $job_file to edit it?"
    yes_no_dialog "$message" && $EDITOR "$job_file"

    message="Open file $filterfrom_file to edit it?"
    yes_no_dialog "$message"  && $EDITOR "$filterfrom_file"

    message_box "Finished editting job $job_basename!"
}

function remove_job() {
    local job_file=$1
    local job_basename; job_basename=$(basename "$job_file")
    local filterfrom_file="$conf_path/filterfrom/$job_basename.filter"
    local lock_file="$conf_path/lock/$job_basename.lock"
    local log_file="$conf_path/log/$job_basename.log"

    local files_to_remove=()
    [[ -f $job_file ]]        && files_to_remove+=("$job_file")
    [[ -f $filterfrom_file ]] && files_to_remove+=("$filterfrom_file")
    [[ -f $lock_file ]]       && files_to_remove+=("$lock_file")
    [[ -f $log_file ]]        && files_to_remove+=("$log_file")
   
    local message=()
    message+=("The following files will be permanently REMOVED: \n")
    local file
    for file in "${files_to_remove[@]}"; do
        message+=("- $file \n")
    done
    message+=("\n" "WARNING: This operation is IRREVERSIBLE.") # two items so ask_for_confirmation draws the proper height
    ask_for_confirmation "${message[@]}" || return 0

    rm "${files_to_remove[@]}"

    message_box "Job $job_basename removed!"
}

function show_log() {
    local job_file=$1
    local log_file; log_file="$conf_path/log/$(basename "$job_file").log"
    if [[ -f $log_file ]]; then
        # shellcheck disable=SC2046  # $(stty size) outputs fullscreen height and width
        whiptail --backtitle "${script_name:?}" --title "$log_file" --textbox "$log_file" $(stty size) --scrolltext
    else
        error_box "ERROR: Could not find file $log_file."
    fi
}