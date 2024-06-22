#!/usr/bin/env bash

###################################################################
# Script Name : rclone-tasks-run.sh
# Description : This script it's not intended to be run by itself,
#               if should be called by rclone-jobman.
#               This script runs a single task, taking the parameters from a file.
# Args        : task_config_file: the path to a file containing the task description
# Author      : CarlesCN
# E-mail      : carlesbioinformatics@gmail.com
# License     : GNU General Public License v3.0
###################################################################

# -e script ends on error (exit != 0)
# -u error if undefined variable
# -o pipefail script ends if piped command fails
set -euo pipefail


source "$RCLONETASKS_BIN_PATH/utils.sh"


# Parse arguments
POSITIONAL_ARGS=()
FORCE_DRY_RUN=false
while [ $# -gt 0 ]; do
    case $1 in
        -n|--dry-run)
            FORCE_DRY_RUN=true
            shift # past argument
            ;;
        -*)
            echo "Unknown option '$1'"
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift # past argument
            ;;
    esac
done

if [ ${#POSITIONAL_ARGS[@]} -gt 1 ]; then
    echo "Too many arguments: '${POSITIONAL_ARGS[*]}'"
    exit 1
fi


# Check for files
TASK_FILE="${POSITIONAL_ARGS[0]}"
if [ ! -f "$TASK_FILE" ]; then
    echo "file '$TASK_FILE' not found"
    exit 1
fi

if [ ! -f "$RCLONETASKS_RCLONE_CONFIG_FILE" ]; then
    echo "Could not find rclone configuration file: '$RCLONETASKS_RCLONE_CONFIG_FILE'"
    exit 1
fi

if [ ! -d "$RCLONETASKS_LOG_PATH" ]; then mkdir -p "$RCLONETASKS_LOG_PATH"; fi
if [ ! -d "$RCLONETASKS_LOCK_PATH" ]; then mkdir -p "$RCLONETASKS_LOCK_PATH"; fi


# Read params from file
BASENAME=$(basename "$TASK_FILE")
TASK_NAME=$(get_value_from_file "$TASK_FILE" 'name')
SOURCE_PATH=$(get_value_from_file "$TASK_FILE" 'source_path')
DEST_PATH=$(get_value_from_file "$TASK_FILE" 'destination_path')
FILTERFROM_FILE=$(get_value_from_file "$TASK_FILE" 'filterfrom_file')

DRY_RUN=$(get_value_from_file "$TASK_FILE" dry_run)
if [ "$DRY_RUN" == "FALSE" ]; then DRY_RUN=false; else DRY_RUN=true; fi
if $FORCE_DRY_RUN; then DRY_RUN=true; fi

# Set some file paths
LOCK_FILE="$RCLONETASKS_LOCK_PATH/$BASENAME.lock"
LOG_FILE="$RCLONETASKS_LOG_PATH/$BASENAME.log"

# Remove last log file to keep its size manageable
if [ -f "$LOG_FILE" ]; then rm "$LOG_FILE"; fi


# Print info
echo ""
if $DRY_RUN; then echo "INFO: --dry-run is set. This will NOT make any real changes."; fi
echo "Starting task '$TASK_NAME'..."
echo "Source path . . : $SOURCE_PATH"
echo "Destination path: $DEST_PATH"
echo ""
# Display notification
notify-send "Starting rclone-tasks for $TASK_NAME"


# Set the rclone arguments
## makes destination identic to source
RCLONE_ARGS=(sync)
## dry run: rclone will NOT actually write to destination.
## This is controlled by the "DRY_RUN=" line in the task config file
if $DRY_RUN; then RCLONE_ARGS+=(--dry-run); fi
## read config from $RCLONETASKS_RCLONE_CONFIG_FILE
RCLONE_ARGS+=(--config "$RCLONETASKS_RCLONE_CONFIG_FILE")
## set log level
## INFO: prints everything but debug events
## DEBUG: prints ALL events
RCLONE_ARGS+=(--log-level INFO)
## save log to file
RCLONE_ARGS+=(--log-file "$LOG_FILE")
## filter files as in filter-from file
RCLONE_ARGS+=(--filter-from "$FILTERFROM_FILE")
## show progress
RCLONE_ARGS+=(--progress)
## store local symlinks as text files '*.rclonelink' in remote server
RCLONE_ARGS+=(--links)
## deletes files after copying is finalized
RCLONE_ARGS+=(--delete-after)
## remove all non-tracked files (BE CAUTIOUS!)
# RCLONE_ARGS+=(--delete-excluded)
## moved files will be moved remotely server-side, instead of deleted and reuploaded
## (can be slow, doesn't work with encryption)
# RCLONE_ARGS+=(--track-renames)
## speed up by increasing the number of simultaneous tranfers
# RCLONE_ARGS+=(--transfers 10)
## speed up by increasing the number of simultaneous checkers
# RCLONE_ARGS+=(--checkers 20)
## Source path
RCLONE_ARGS+=("$SOURCE_PATH")
## Destination path
RCLONE_ARGS+=("$DEST_PATH")


# Call rclone using flock to prevent re-running a task that is already running
flock -n "$LOCK_FILE" rclone "${RCLONE_ARGS[@]}"
