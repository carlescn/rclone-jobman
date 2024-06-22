#!/usr/bin/env bash

function get_value_from_file { # $1=file, $2=key
    # Tries to read key & value pair from file and returns the value of the first occurrence.
    # Key and value must be separated by '='.
    # Line must begin with key (no leading white spaces).
    # It returns everything to the right of '=', trimming leading and trailing spaces.
    value=$(awk -F'=' '/^'"$2"'/ {sub(/^ */, "", $2); sub(/ *$/, "", $2); print $2; exit}' "$1" )
    if [[ -z "$value" ]]; then
        echo "ERROR: Key '$2' is missing in your configuration file."
        exit 1
    fi
    echo "$value"
}