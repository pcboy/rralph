#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/odd_even.sh"

passed=0
failed=0

test_case() {
    local input="$1"
    local expected="$2"
    local description="$3"
    
    local result
    result=$(bash "$SCRIPT" "$input" 2>&1)
    
    if [[ "$result" == *"$expected"* ]]; then
        echo "✓ PASS: $description"
        passed=$((passed + 1))
    else
        echo "✗ FAIL: $description"
        echo "  Input: $input"
        echo "  Expected: $expected"
        echo "  Got: $result"
        failed=$((failed + 1))
    fi
}

echo "Testing IS EVEN / IS ODD output..."
echo ""

test_case 0 "IS EVEN" "0 should print IS EVEN"
test_case 7 "IS ODD" "7 should print IS ODD"
test_case -4 "IS EVEN" "-4 should print IS EVEN"
test_case 2 "IS EVEN" "2 should print IS EVEN"
test_case -3 "IS ODD" "-3 should print IS ODD"

echo ""
echo "Results: $passed passed, $failed failed"

if [[ $failed -gt 0 ]]; then
    exit 1
fi
