#!/usr/bin/env bash

###################################################################
# Library Name : rclone-jobman.sh
# Description  : This library is part of rclone-jobman.
#                It contains functions to create a new job.
#                See main script for author and contact info.
###################################################################

function promptIfFileExists() {
    [[ -f "$1" ]] || return 0
    echo "WARNING: file $1 already exists. Do you want to overwrite it?"
    askConfirmation || return $?
}

function createNewJob() {
    local jobBasename jobName dryrun sourcePath destinationPath

    echo "rclone-jobman: NEW JOB"
    echo "Please input the following fields:"

    read -r -p "New job filename: " jobBasename
    [[ -z $jobBasename ]] && echo "Field cannot be empty!" && return 1

    local jobFile="${confPath:?}/jobs/$jobBasename";
    local filterfromFile="$confPath/filter-from/$jobBasename.filter";
    local lockFile="$confPath/lock/$jobBasename.lock";
    local logFile="$confPath/log/$jobBasename.log";
    promptIfFileExists "$jobFile"        || return 0
    promptIfFileExists "$filterfromFile" || return 0
    promptIfFileExists "$lockFile"       || return 0
    promptIfFileExists "$logFile"        || return 0

    read -r -p "Descriptive name: "  jobName
    [[ -z $jobName ]] && echo "Field cannot be empty!" && return 1
    read -er -p "Source path: "      sourcePath
    [[ -z $sourcePath ]] && echo "Field cannot be empty!" && return 1
    read -er -p "Destinatino path: " destinationPath
    [[ -z $destinationPath ]] && echo "Field cannot be empty!" && return 1
    echo "Dry-run is set to TRUE by default. You can set it to FALSE now. Or edit it later. "
    read -r -p "Type FALSE to set dryrun to FALSE. : " dryrun
    [[ "$dryrun" == "FALSE" ]] || dryrun="TRUE"

    echo "Is this correct?"
    echo "File name:        $jobBasename"
    echo "Descriptive name: $jobName"
    echo "Source path:      $sourcePath"
    echo "Destination path: $destinationPath"
    echo "--dry-run option: $dryrun"
    askConfirmation || return 0

    # Write the $jobFile
    {   echo "# Descriptive name for the sync job"
        echo "jobName=$jobName"
        echo "# For testing purposes, set to TRUE and rclone will NOT write anything to the remote server."
        echo "dryrun=$dryrun"
        echo "# Paths for source (READ) and destination (WRITE)"
        echo "sourcePath=$sourcePath"
        echo "destinationPath=$destinationPath"
    } > "$jobFile"

    # Remove and recreate $lockFile to ensure proper ownership (user:group)
    [[ -f "$lockFile" ]] && rm "$lockFile"
    touch "$lockFile"

    # Remove log file so menu says it has never been run.
    [[ -f "$logFile" ]] && rm "$logFile"

    # Write the $filterfromFile and open with default editor
    {   echo "# This is the filter-from file for the job $jobFile."
        echo "# Check out https://rclone.org/filtering/#filter-from-read-filtering-patterns-from-a-file for reference."
    } > "$filterfromFile"
    echo "I will now open the file $filterfromFile so you can edit it."
    pressAnyKey || return 0
    /usr/bin/env editor "$filterfromFile"
}