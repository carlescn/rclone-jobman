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

USER=$(whoami)
CONFPATH="/home/$USER/.config/rclone-jobman"

doBasicChecks(){
# Check that some basic things are set correctly
  # The needed variables are set in the job file
  if [ -z "$jobName" ]; then
    echo "jobName is missing in your configuration file. Exiting"
    exit 1
  elif [ -z "$sourcePath" ]; then
    echo "sourcePath is missing in your configuration file. Exiting"
    exit 1
  elif [ -z "$destinationPath" ]; then
    echo "destinationPath is missing in your configuration file. Exiting"
    exit 1
  fi

  # Some needed files do exist
  if [ ! -f "$configFile" ]; then
    echo "rclone config file $configFile not found. Exiting."
    exit 1
  elif [ ! -f "$filterfromFile" ]; then
    echo "filter-from file $filterfromFile not found. Exiting."
    exit 1
  fi
}

printJobInfo(){
# Prints info of the sync job that will be run
	echo -e "\nRunning sync job \"$jobName\"..."

	if [ "$dryrun" == "-n" ]; then
	  echo "INFO: dry-run is set to YES. It will NOT make any real changes."
	else
	  echo "INFO: dry-run is set to NO. It WILL actually WRITE / DELETE files."
	fi

	echo "Source path . . : $sourcePath"
	echo "Destination path: $destinationPath"
	echo "Filter-from file: $filterfromFile"
	echo "Log file. . . . : $logFile"
	echo "Config file . . : $configFile"
	echo "" # Blank line
}


setRcloneOptions(){
# Set fixed options for Rclone
  # Set some file paths:
  configFile="/home/$USER/.config/rclone/rclone.conf"
  logFile="$CONFPATH/log/$jobBasename.log"
  filterfromFile="$CONFPATH/filter-from/$jobBasename.filter"
	lockFile="$CONFPATH/lock/$jobBasename.lock"

  # Set rclone options:
  # --config: read config from $configFile.
  # --log-level:       INFO: prints everything but debug events. DEBUG: prints ALL events.
	# --log-file:        save log in $logFile.
	# --filter-from:     filter files as in $filterfromFile.
  # -n:                dry-run: it will NOT actually make any changes in remote server. This is controlled by the (un)commented line in the job config file.
	# -P:                show progress.
	# -l:                store local symlinks as text file '.rclonelink' in remote server.
	# --track-renames:   moved / renamed files will be moved remotely server-side. If not set, the "new" file will be reuploaded and the "old" one deleted.
	config="--config $configFile"
	log="--log-level INFO --log-file $logFile"
	filter="--filter-from $filterfromFile"
	options="$config $log $filter $dryrun -P -l --track-renames"
}


callRclone(){
# Calls rclone and makes de sync job happen
	# Display notification
  DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus notify-send "Syncing $jobName"
	# Remove last log file to keep it manageable
  rm $logFile
	# Call rclone (flock won't allow it if it is already running ($lockFile exists).
  flock -n $lockFile rclone sync $options $sourcePath $destinationPath

}

doJob(){
# Takes user input as $1 (must be a number from 0 to $numFiles)
# Loads the config options from the corresponding file and calls Rclone
  jobBasename=$(basename $jobFile)
  source $jobFile
  setRcloneOptions
  doBasicChecks
  printJobInfo
  callRclone
}


menuItem(){
# Prints info for every sync configuration
  # Calculate days and hours since last modification of logFile
  timeLastModified=$(date +%s -r $logFile) # Time of last modification, in seconds
  timeNow=$(date +%s) # Current time, in seconds
  seconds=$((timeNow - timeLastModified))
  days=$((seconds/86400))
  hours=$(((seconds%86400)/3600))

  # Print menu item
  echo "$i) $jobName"
  echo "   Last sync: $days days $hours hours ago"
}


buildMenu(){
# Reads all the config files and calls menuItem() for each one to build the menu
  # Get all files in ./config, save as an array
  listFiles=($(ls -d $CONFPATH/jobs/*))

  echo "List of available jobs:"
  for i in ${!listFiles[@]}; do
    source ${listFiles[$i]}
    logFile="$CONFPATH/log/$(basename ${listFiles[$i]}).log"
    menuItem
  done
  numFiles=$i
}


runMenu(){
# Print the menu and expect user input:
  while true; do
    buildMenu
    read -p "Choose 0-$numFiles (or Q to exit): " userInput
    case $userInput in
      [0-$numFiles])
        jobFile=$(realpath ${listFiles[$userInput]})
        doJob
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
  jobFile="$CONFPATH/jobs/$1"
  if [ -f "$jobFile" ]; then
    doJob
  else
    echo "File $jobFile not found. Exiting."
    exit 1
  fi
}


# Check if some argument is passed and call runFile(). if not, call runMenu().
if [ "$1" ]; then
  runFile $1
else
  runMenu
fi

