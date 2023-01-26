# rclone-jobman

[![GPLv3 license](https://img.shields.io/badge/License-GPLv3.0-blue.svg)](https://github.com/carlescn/rclone-jobman/blob/main/LICENSE)
[![made-with-bash-5.1](https://img.shields.io/badge/Made%20with-Bash%205.1-1f425f.svg?logo=gnubash)](https://www.gnu.org/software/bash/)
[![Linux](https://img.shields.io/badge/OS-Linux-yellow.svg?logo=linux)](https://www.linux.org/)
[![rclone-1.53.3](https://img.shields.io/badge/rclone-1.53.3-darkgreen.svg)](https://rclone.org/)

## About

**rclone-jobman** is a "job manager" 
that aims to simplify managing multyple sync jobs 
with [rclone](https://rclone.org/).

I first wrote it as a very simple script 
for my specific necessities, 
but later I thought it would be a good exercice 
to try and make it more convenient for general use. 
So I expanded it adding subscripts 
for adding, editing and removing jobs.

For now, the rclone arguments are "hard-coded" 
(I mean, this is a script after all...) 
for the way I use rclone. 
I may change this in the future 
and make the arguments job-specific, 
saving them on the [job file](#job-files) instead.

## Usage

If rclone-jobman is called without any argument
(the main intended use), 
it will run in interactive mode. 
It will print a menu 
listing all the available jobs and options
and wait for user input.
Here you can run a sync job
or create/edit/remove one.

Alternatively,
it can be called with only one argument
that should be the name of a [job file](#job-files)
(only the basename, not the full path).
It will run this specific job and exit.
This is intended to be used to automate backups,
for example using cron
(see [example file](https://github.com/carlescn/rclone-jobman/blob/main/example_files/cron_file_example)).

## Job files

Each job is defined on a **job file**
which defines a descriptive name,
a source and a destination paths,
and if the rclone should be run with the --dry-run option.
The basename of each job file will be used to uniquely identify it.

Each job has three more files,
that must be named with the same unique basename:  

- A **filter-from file** defines the patters that rclone will use 
  to filter files from the source directory
  (see https://rclone.org/filtering/#filter-from-read-filtering-patterns-from-a-file)
- A **log file**, where rclone will save the log of the last run.
  This file is erased at the start of every run.
- A **lock file**, used with 
  [flock](https://manpages.debian.org/testing/util-linux/flock.1.en.html)
  to prevent the job to be started 
  if the last execution has not ended,
  which could happen when used with automation.

## Folder structure

The main script rclone-jobman.sh is intended to be put
(or linked to)
on one of the `$PATH` directories.
The other subscripts (rclone-jobman-*.sh) must be in the same directory, 
with the main script.

The job files must be put under the `$HOME/.config/` directory
following this structure:

- `rclone-jobman/jobs/`: job files
- `rclone-jobman/filter-from/`: filter-from files
- `rclone-jobman/log/`: log files
- `rclone-jobman/lock/`: lock files

## Desktop entry

I provide a desktop entry file
for executing the main script on a terminal
from the graphical desktop environment:
[rclone-jobman.desktop](https://github.com/carlescn/rclone-jobman/blob/main/rclone-jobman.desktop).
It should be placed under `$HOME/.local/share/applications/`.
For it to show an icon correctly,
[rclone.png](https://github.com/carlescn/rclone-jobman/blob/main/rclone.png)
must be placed under `$HOME/.local/share/icons/`
(this file is taken from the
[rclone-webui-react repository](https://github.com/rclone/rclone-webui-react)).

## Install

I provide a script named 
[install-rclone-jobman.sh](https://github.com/carlescn/rclone-jobman/blob/main/install-rclone-jobman.sh)
that "installs" all the files 
(including the desktop entry and icon)
on the user environment,
and creates the necessary subdirectories under .config.