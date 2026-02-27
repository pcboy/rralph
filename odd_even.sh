#!/usr/bin/env bash

# Check if argument is provided
if [[ $# -eq 0 ]]; then
    echo "Error: No argument provided" >&2
    exit 1
fi

# Validate input is an integer
if [[ ! $1 =~ ^-?[0-9]+$ ]]; then
    echo "Error: Invalid integer input" >&2
    exit 1
fi

# Check even or odd using arithmetic evaluation
if (( $1 % 2 == 0 )); then
    echo "IS EVEN"
else
    echo "IS ODD"
fi
