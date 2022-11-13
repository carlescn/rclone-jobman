#!/bin/bash

###################################################################
#Script Name : rclone-jobman.sh
#Description : Simple sync job manager for rclone.
#              If an argument is passed, it takes it as a file name
#              and checks for it in ~/.config/rclone-jobman/jobs.
#              Then runs the corresponding sync job.
#              If no argument is passed, it looks for all the files
#              in ~/.config/rclone-jobman/jobs and shows the time
#              since the last time every one has run. Then lets you
#              choose a job tu run and returns you to the menu.
#              (PENDING DOCUMENTATION!).
#Args        : Either nothing or the name of a job file
#Author      : CarlesCN
#E-mail      : drtlof@gmail.com
###################################################################

# Exit the script if any command exits with anything other than 0
set -e

readonly confPath="$HOME/.config/rclone-jobman"

main(){
# Check if some argument is passed and call runFile(). if not, call runMenu().
  if [ "$1" ]; then
    runFile $1
  else
    runMenu
  fi
}


readJobFileLine(){
# Reads line that matches $1 from file $2 and returns the trailing part of the line after the character "="
# If it matches an empty string, exits with 1.
  local line
  
  line=$(grep $1 $2 | cut --fields=2 --delimiter="=")
  
  if [[ -z $line ]]; then
    echo "\"$1=\" is missing in your configuration file or it is empty. Exiting..." >&2
    exit 1
  else
    echo $line
  fi
}


checkFile(){
# Checks that $1 is a file and returns $1. If not, exits with 1.
  if [[ -f $1 ]]; then
    echo $1
  else
    echo "Could not find file \"$1\". Exiting..." >&2
    exit 1
  fi
}


setRcloneOptions(){
# Set options for Rclone
  local jobBasename=$1
  local dryrun=$2
  
  local configFile
  local logFile
  local filterfromFile
	local config
	local log
	local filter
	local options

  # Set some file paths:
  configFile=$(checkFile "$HOME/.config/rclone/rclone.conf") || exit 1
  logFile="$confPath/log/$jobBasename.log"
  filterfromFile=$(checkFile "$confPath/filter-from/$jobBasename.filter") || exit 1

  # Set dryrun option
  if [[ $dryrun == TRUE ]]; then
    dryrun="--dry-run"
  else
    dryrun=""
  fi

  # Set rclone options:
  # --config: read config from $configFile.
  # --log-level:       INFO: prints everything but debug events. DEBUG: prints ALL events.
	# --log-file:        save log in $logFile.
	# --filter-from:     filter files as in $filterfromFile.
  # --dry-run:         rclone will NOT actually make any changes in remote server. This is controlled by the "dryrun=" line in the job config file.
	# --progress:        show progress.
	# --links:           store local symlinks as text file '.rclonelink' in remote server.
	# --track-renames:   moved / renamed files will be moved remotely server-side. If not set, the "new" file will be reuploaded and the "old" one deleted.
	config="--config $configFile"
	log="--log-level INFO --log-file $logFile"
	filter="--filter-from $filterfromFile"
	options="$config $log $filter $dryrun --progress --links --track-renames"

	echo $options
}


printJobInfo(){
# Prints some info of the sync job that will be run
  local jobName=$1
  local sourcePath=$2
  local destinationPath=$3
  local dryrun=$4
  
	echo -e "\nRunning job \"$jobName\"..."

	if [ "$dryrun" == "TRUE" ]; then
	  echo "INFO: dry-run is set to YES. It will NOT make any real changes."
	else
	  echo "INFO: dry-run is set to NO. It WILL actually WRITE / DELETE files."
	fi

	echo "Source path . . : $sourcePath"
	echo "Destination path: $destinationPath"
	echo "" # Blank line
}


callRclone(){
# Calls rclone and makes de sync job happen
  local jobName=$1
  local jobBasename=$2
  local options=$3
  local sourcePath=$4
  local destinationPath=$5

  local lockFile
  local logFile
  
	lockFile="$confPath/lock/$jobBasename.lock"
  logFile="$confPath/log/$jobBasename.log"
  
	# Display notification
  DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus notify-send "Syncing $jobName"
	# Remove last log file to keep it manageable
  rm --force $logFile
	# Call rclone (flock won't allow it if it is already running ($lockFile exists).
  flock -n $lockFile rclone sync $options $sourcePath $destinationPath
}


doJob(){
# Takes jobFile path as $1, reads the options and calls Rclone
  local jobFile=$1

  local jobBasename
  local jobName
  local sourcePath
  local destinationPath
  local dryrun
  local options
  
  jobBasename=$(basename $jobFile)
  jobName=$(readJobFileLine "jobName" $jobFile)
  sourcePath=$(readJobFileLine "sourcePath" $jobFile)
  destinationPath=$(readJobFileLine "destinationPath" $jobFile)
  dryrun=$(readJobFileLine "dryrun" $jobFile)
  options=$(setRcloneOptions $jobBasename $dryrun)

  printJobInfo "$jobName" $sourcePath $destinationPath $dryrun

  callRclone "$jobName" $jobBasename "$options" $sourcePath $destinationPath
}


printTime(){
# Prints time last modification of logFile
  local logFile=$1

  local timeLastModified=$(date +%s -r $logFile) # Time of last modification, in seconds
  local timeNow=$(date +%s) # Current time, in seconds
  local seconds=$((timeNow - timeLastModified))
  local days=$((seconds/86400))
  local hours=$(((seconds%86400)/3600))
  echo "   Last sync: $days days $hours hours ago"
}


buildMenu(){
# Reads all the config files and prints the menu
  local -n files=$1
  local -n num=$2

  local i
  local jobFile
  local jobName
  local logFile
  
  # Get all the files in the jobs folder, store them in an array
  files=($(ls -d $confPath/jobs/*))

  echo "List of available jobs:" >&2
  for i in ${!files[@]}; do
    # Read from file
    jobFile=${files[$i]}
    jobName=$(readJobFileLine "jobName" $jobFile)
    logFile="$confPath/log/$(basename $jobFile).log"
    # Print menu item
    echo "$i) $jobName"
    printTime $logFile
  done
  
  num=$i
}


runMenu(){
# Calls buildMenu and asks for user input
  local filesList
  local numFiles
  local jobFile
  
  while true; do
    buildMenu filesList numFiles
    read -p "Choose 0-$numFiles (or Q to exit): " userInput
    case $userInput in
      [0-$numFiles])
        jobFile=$(realpath ${filesList[$userInput]})
        doJob $jobFile
        ;;
      q|Q|exit)
        break;;
      *)
        echo "Sorry! Invalid option, try again.";;
    esac
  done
}


runFile(){
# Check that file name from $1 exists and call doJob(). If not, exit with error.
  local jobFile="$confPath/jobs/$1"
  
  if [ -f "$jobFile" ]; then
    doJob
  else
    echo "File $jobFile not found. Exiting."
    exit 1
  fi
}

main "${@}"
