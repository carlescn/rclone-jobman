# rclone-jobman
Simple script to manage multiple rclone sync jobs

## Files and folders

- `bin/rclone-jobman.sh`: main script
- `.config/rclone-jobman/jobs/`: One file for each job
- `.config/rclone-jobman/filter-from/`: One file for each job, the base name must be the same
- `.config/rclone-jobman/log/`: Log files for each backup job will be saved here
- `.config/rclone-jobman/lock/`: flock will use this files to prevent execution if job is already running
- `cron/rclone-jobman_00_example`: example of file you can put on `/etc/cron.*/`

## ToDo:

- Full documentation
