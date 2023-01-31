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
    local files_array job_file job_name user_input index 
    while true; do
        # Get all the files in the jobs folder
        mapfile -t files_array < <(ls -d "${conf_path:?}"/jobs/*)
        
        # Print the menu
        echo "" # Blank line for clearer presentation
        echo "rclone-jobman - $name_function:"
        for index in "${!files_array[@]}"; do
            job_file=${files_array[$index]}
            job_name=$(read_job_file_line "$job_file" job_name)
            echo "$index) $job_name"
        done
        echo "-----------------------"
        echo "q) Return to main menu."
        
        # Read the user input
        read -r -p "Choose one option: " user_input; echo""
        case $user_input in
            [0-$index])  "$call_function" "$(realpath "${files_array[$user_input]}")" ;;
            q|Q)       return 0 ;;
            *)         echo "Invalid option, try again!" ;;
        esac
    done
}

function edit_job() {
    local job_file=$1
    local job_basename; job_basename=$(basename "$job_file");           exit_if_file_missing "$job_file"
    local filterfrom_file="$conf_path/filterfrom/$job_basename.filter"; exit_if_file_missing "$filterfrom_file"

    echo "Opening file $job_file with your default text editor."
    press_any_key && /usr/bin/env editor "$job_file"

    echo "Opening file $filterfrom_file with your default text editor."
    press_any_key && /usr/bin/env editor "$filterfrom_file"

    echo "Done!"
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
   
    echo "This will remove the following files:"
    local file
    for file in "${files_to_remove[@]}"; do
        echo "  $file"
    done
    echo "This operation is irreversible. Are you sure?"
    ask_for_confirmation || return 0

    rm "${files_to_remove[@]}"
}

function show_log() {
    local job_file=$1
    local log_file; log_file="$conf_path/log/$(basename "$job_file").log"
    if [[ -f $log_file ]]; then
        echo "[BEGIN $log_file]"
        more "$log_file"
        echo "[END $log_file]"
    else
        echo "ERROR: Could not find file $log_file." >&2
    fi
}