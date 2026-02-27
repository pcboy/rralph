#!/usr/bin/env bash

SCRIPT="./odd_even.sh"
PASSED=0
FAILED=0

test_case() {
    local input="$1"
    local expected_output="$2"
    local expected_exit="$3"
    local description="$4"

    if [[ -z "$input" ]]; then
        output=$("$SCRIPT" 2>&1)
        exit_code=$?
    else
        output=$("$SCRIPT" "$input" 2>&1)
        exit_code=$?
    fi

    if [[ "$output" == "$expected_output" && "$exit_code" == "$expected_exit" ]]; then
        echo "PASS: $description"
        ((PASSED++))
    else
        echo "FAIL: $description"
        echo "  Input: '$input'"
        echo "  Expected: '$expected_output' (exit $expected_exit)"
        echo "  Got: '$output' (exit $exit_code)"
        ((FAILED++))
    fi
}

echo "Running odd_even.sh tests..."
echo

test_case "0" "IS EVEN" 0 "Input 0 should be EVEN"
test_case "7" "IS ODD" 0 "Input 7 should be ODD"
test_case "-4" "IS EVEN" 0 "Input -4 should be EVEN"
test_case "abc" "Error: Invalid integer input" 1 "Input 'abc' should error"
test_case "" "Error: No argument provided" 1 "No argument should error"

echo
echo "Results: $PASSED passed, $FAILED failed"

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
exit 0
