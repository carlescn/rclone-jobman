# rclone-jobman

This is a simple script I wrote to help me manage multiple sync jobs with [rclone](https://rclone.org/).

You can take it and modify it to fit your needs. All the rclone arguments are set in the funtion `setRcloneOptions()`.

## Usage

If *rclone-jobman* is called without any argument, it will look for files in `~/.config/rclone-jobman/jobs/`, which define the jobs that can be run. It will print a menu with all the job names and the time since they last run (calculated from de log file date). Then it will ask to select a job to run, run it and return to the menu.

Alternatively, it can be called with the name of a file in `~/.config/rclone-jobman/jobs/` as an argument (must be the base name, not the full path). It will run this specific job and exit. This can be used to automate backups with *cron* (see example in `cron/rclone-jobman_00_example`).

Each job is defined with a file on `.config/rclone-jobman/jobs/` (one file per job). It must contain a descriptive name, a source path and a destination path. The base name of each file will be used to define the rest of the files related to this job.

A *filter-from* file (see https://rclone.org/filtering/#filter-from-read-filtering-patterns-from-a-file) should be created for every job and saved in `.config/rclone-jobman/filter-from/`, as in the example files provided.

For every job run, the output from rclone will be saved in a log file in `.config/rclone-jobman/log/`. It will be erased at the start of every run.

[flock](https://manpages.debian.org/testing/util-linux/flock.1.en.html) is used to prevent the job to be started if the last execution has not ended. For this, a lock file is created under `.config/rclone-jobman/lock/` with the sema base name as the job file.

## Files and folders

`bin` and `.config` folders should be put on the `$HOME` directory.

- `bin/rclone-jobman.sh`: the main script
- `.config/rclone-jobman/jobs/`: One file for each job
- `.config/rclone-jobman/filter-from/`: One file for each job, the base name must be the same
- `.config/rclone-jobman/log/`: Log files for each job will be saved here
- `.config/rclone-jobman/lock/`: lock files used by flock
- `cron/rclone-jobman_00_example`: example of file you can put on `/etc/cron.*/` for automation.

## ToDo:

- Rewrite using local variables
- Better documentation
