#!/usr/bin/env bash

###################################################################
# Script Name : install-rclone-jobman.sh
# Description : For use with rclone-jobman. This "installs" the
#               scripts, desktop entry and icon on the user environment
#               and creates the necessary .config subdirectories.
# Args        : None
# Author      : CarlesCN
# E-mail      : carlesbioinformatics@gmail.com
# License     : GNU General Public License v3.0
###################################################################

# -e script ends on error (exit != 0)
# -u error if undefined variable
# -o pipefail script ends if piped command fails
set -euo pipefail

readonly apps_dir="$HOME/.local/share/applications"
readonly icons_dir="$HOME/.local/share/icons"
readonly bin_dir="$HOME/.local/bin"

[[ -z $HOME ]] && echo -e "ERROR: \$HOME variable is not set." && exit 1
[[ ! -d "$apps_dir" ]] && echo "ERROR: directory $apps_dir not found." && exit 1
[[ ! -d "$icons_dir" ]] && echo "ERROR: directory $icons_dir not found." && exit 1
[[ $PATH == ?(*:)$bin_dir?(:*) ]] || echo -e "WARNING: $bin_dir is not on your \$PATH."

[[ -d "$bin_dir" ]] || mkdir -p "$bin_dir"
cp ./bin/* "$bin_dir/"
cp ./rclone-jobman.desktop "$apps_dir/"
cp ./rclone.png "$icons_dir/"

mkdir -p "$HOME/.config/rclone-jobman/jobs"
mkdir -p "$HOME/.config/rclone-jobman/filter-from"
mkdir -p "$HOME/.config/rclone-jobman/log"
mkdir -p "$HOME/.config/rclone-jobman/lock"

exit 0