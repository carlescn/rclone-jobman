#!/usr/bin/env bash

###################################################################
# Script Name : install-rclone-jobman.sh
# Description : For use with rclone-jobman. This "installs" the
#               scripts, desktop entry and icon on the user environment
#               and creates the necessary .config subdirectories.
# Args        : None
# Author      : CarlesCN
# E-mail      : drtlof@gmail.com
# License     : GNU General Public License v3.0
###################################################################

# -e script ends on error (exit != 0)
# -u error if undefined variable
# -o pipefail script ends if piped command fails
set -euo pipefail

readonly appsdir="$HOME"/.local/share/applications
readonly iconsdir="$HOME"/.local/share/icons
readonly bindir="$HOME"/bin

[[ -z $HOME ]] && echo -e "ERROR: \$HOME variable is not set." && exit 1
[[ ! -d "$appsdir" ]] && echo "ERROR: directory $appsdir not found." && exit 1
[[ ! -d "$iconsdir" ]] && echo "ERROR: directory $iconsdir not found." && exit 1
[[ $PATH == ?(*:)$bindir?(:*) ]] || echo -e "WARNING: $bindir is not on your \$PATH."

[[ -d "$bindir" ]] || mkdir -p bindir
cp ./bin/* "$bindir"/
cp ./rclone-jobman.desktop "$appsdir"/
cp ./rclone.png "$iconsdir"/

mkdir -p "$HOME"/.config/rclone-jobman/jobs
mkdir -p "$HOME"/.config/rclone-jobman/filter-from
mkdir -p "$HOME"/.config/rclone-jobman/log
mkdir -p "$HOME"/.config/rclone-jobman/lock

exit 0