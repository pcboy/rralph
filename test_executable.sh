#!/usr/bin/env bash

# Test that odd_even.sh is executable

script_path="$(dirname "$0")/odd_even.sh"

if [ -x "$script_path" ]; then
    echo "PASS: odd_even.sh is executable"
    exit 0
else
    echo "FAIL: odd_even.sh is not executable"
    exit 1
fi
