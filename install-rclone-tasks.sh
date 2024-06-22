#!/usr/bin/env bash

###############################################################################
# [install-rclone-tasks.sh]
# This script is part of rclone-tasks.
# It copies the scripts, creates a symlink the user .local/bin directory,
# copies the desktop entry and icon on the corresponding user .local directories
# and creates the necessary subdirectories in .config.
# Arguments: (None)
#
# Author: CarlesCN
# E-mail: carlesbioinformatics@gmail.com
# License: GNU General Public License v3.0
###############################################################################

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
cp ./rclone-tasks.desktop "$apps_dir/"
cp ./rclone.png "$icons_dir/"

mkdir -p "$HOME/.config/rclone-tasks/tasks"
mkdir -p "$HOME/.config/rclone-tasks/log"
mkdir -p "$HOME/.config/rclone-tasks/lock"

exit 0