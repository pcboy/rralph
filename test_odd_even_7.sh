#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/odd_even.sh"

echo "Testing odd_even.sh with input 7..."

output=$(bash "$SCRIPT" 7)
exit_code=$?

if [[ $exit_code -ne 0 ]]; then
    echo "FAIL: Expected exit code 0, got $exit_code"
    exit 1
fi

if [[ "$output" == "IS ODD" ]]; then
    echo "PASS: Output is 'IS ODD'"
    exit 0
else
    echo "FAIL: Expected 'IS ODD', got '$output'"
    exit 1
fi
