#!/usr/bin/env bash

###################################################################
#Script Name : rclone-jobman.sh
#Description : Simple sync-job manager for rclone.
#              If no argument is passed, it looks for all the files in ~/.config/rclone-jobman/jobs.
#              Shows their names and the time since their where last run.
#              Then lets you choose a job tu run. Once finished, it returns to the menu.
#              It also accepts one file name as a parameter,
#              which must exist in ~/.config/rclone-jobman/jobs.
#              If so, it runs the corresponding job.
#Args        : Either nothing or the name of a job file.
#Author      : CarlesCN
#E-mail      : drtlof@gmail.com
###################################################################

# -e script ends on error (exit != 0)
# -u error if undefined variable
# -o pipefail script ends if piped command fails
set -euo pipefail

readonly scriptName="rclone-jobman.sh"
readonly confPath="$HOME/.config/rclone-jobman"

function usage() {              # Intended usage
    echo "Usage: $scriptName [ job_file ]"
}

function exitBadUsage() {       # exit code 1
    usage; exit 1;
}

function exitIfFileMissing() {  # exit code 2
    if [[ ! -f "$1" ]]; then
        echo "ERROR: Could not find file \"$1\"." >&2
        exit 2
    fi
}

function exitMissingKey() {     # exit code 3
    echo "ERROR: Key \"$1\" is missing in your configuration file, or it is empty." >&2
    exit 3
}

function readJobFileLine() {
    local file=$1
    local key=$2
    local value; value=$(grep "$key" "$file" | cut --fields=2 --delimiter="=")
    test -z "$value" && exitMissingKey "$key"
    echo "$value"
}

function callRclone() {
    local jobFile=$1

    # Read params from file
    local dryrun; dryrun=$(readJobFileLine "$jobFile" dryrun)
    local jobName; jobName=$(readJobFileLine "$jobFile" jobName)
    local sourcePath; sourcePath=$(readJobFileLine "$jobFile" sourcePath)                 # can't check if dir exists, could be in remote
    local destinationPath; destinationPath=$(readJobFileLine "$jobFile" destinationPath)  # can't check if dir exists, could be in remote
    local jobBasename; jobBasename=$(basename "$jobFile")

    # Set some file paths
    local configFile="$HOME/.config/rclone/rclone.conf";              exitIfFileMissing "$configFile"
    local filterfromFile="$confPath/filter-from/$jobBasename.filter"; exitIfFileMissing "$filterfromFile"
    local lockFile="$confPath/lock/$jobBasename.lock"                 # it's OK if file doesn't exist
    local logFile="$confPath/log/$jobBasename.log"                    # it's OK if file doesn't exist
    test -f "$logFile" && rm "$logFile" # Remove last log file to keep its size manageable

    # Print the job info
    echo -e "\nRunning job \"$jobName\"..."
    echo -e "Source path . . : $sourcePath \nDestination path: $destinationPath"
    test "$dryrun" == "TRUE" && echo "INFO: --dry-run is set. This will NOT make any real changes."
    echo ""
    # Display a notification
    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus notify-send "Starting sync $jobName"

    # Set the rclone parameters                         # Params description:
    local rcloneParams=(sync)                           # makes destination identic to source
    rcloneParams+=(--config "$configFile")              # read config from $configFile.
    rcloneParams+=(--log-level INFO)                    # INFO: prints everything but debug events. DEBUG: prints ALL events.
    rcloneParams+=(--log-file "$logFile")               # save log to $logFile.
    rcloneParams+=(--filter-from "$filterfromFile")     # filter files as in $filterfromFile.
    rcloneParams+=(--progress)                          # show progress.
    rcloneParams+=(--links)                             # store local symlinks as text files '.rclonelink' in remote server.
    rcloneParams+=(--track-renames)                     # moved files will be moved remotely server-side (instead of deleted and reuploaded)
    test "$dryrun" == TRUE && rcloneParams+=(--dry-run) # rclone will NOT actually write to destination. This is controlled by the "dryrun=" line in the job config file.
    rcloneParams+=("$sourcePath")
    rcloneParams+=("$destinationPath")

    # Call rclone using flock (it will prevent from calling rclone if the job is already running, i.e. $lockFile exists).
    flock -n "$lockFile" rclone "${rcloneParams[@]}" || echo "Job is already running!"
}

function timeSinceModified() {
    local file=$1
    test ! -f "$file" && echo "NEVER!" && return 0
    local seconds; seconds=$(("$(date -u +%s)" - "$(date -ur "$file" +%s)"))
    echo "$((seconds/3600/24)) days and $((seconds/3600%24)) hours"
}

function runInteractive() {
    local filesArray jobFile jobName logFile userInput idx

    # Get all the files in the jobs folder
    mapfile -t filesArray < <(ls -d "$confPath"/jobs/*)

    while true; do
        # Print the menu
        echo "List of available options:"
        for idx in "${!filesArray[@]}"; do
            jobFile=${filesArray[$idx]}; exitIfFileMissing "$jobFile" # Should not be necessary, but just in case...
            jobName=$(readJobFileLine "$jobFile" jobName)
            logFile="$confPath/log/$(basename "$jobFile").log"
            echo "$idx) $jobName"
            echo "   [last sync: $(timeSinceModified "$logFile")]"
        done
        echo "n) Create new job."
        echo "e) Edit job."
        echo "d) Delete job."
        echo "q) Exit."

        # Read the user input
        read -r -p "Choose one: " userInput
        case $userInput in
            [0-$idx]) callRclone "$(realpath "${filesArray[$userInput]}")" ;;
            n|N)      rclone-jobman-newjob.sh || continue ;;
            e|E)      echo "Sorry, still not implemented." ;;
            d|D)      echo "Sorry, still not implemented." ;;
            q|Q|exit) break ;;
            *)        echo "Invalid option, try again!" ;;
        esac
    done
}

runAutomatic(){
    local jobFile="$confPath/jobs/$1"; exitIfFileMissing "$jobFile"
    callRclone "$jobFile"
}

function main() {
    case $# in
        0) runInteractive ;;
        1) runAutomatic "$1" ;;
        *) exitBadUsage ;;
    esac
    exit 0
}

main "${@}"