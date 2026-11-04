#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/inode-test.sh"

FAILED=0

assert_status() {
    local input="$1"
    local expected="$2"
    local actual

    if evaluate_inode "$input" >/dev/null; then
        actual=0
    else
        actual=$?
    fi

    if (( actual == expected )); then
        printf '[PASS] input=%q expected=%d\n' \
            "$input" "$expected"
    else
        printf '[FAIL] input=%q expected=%d actual=%d\n' \
            "$input" "$expected" "$actual"
        FAILED=$((FAILED + 1))
    fi
}

assert_status "50" 0
assert_status "84" 0
assert_status "85" 1
assert_status "100" 1
assert_status "101" 2
assert_status "abc" 2
assert_status "" 2

printf 'Failed tests: %d\n' "$FAILED"

if (( FAILED > 0 )); then
    exit 1
fi

exit 0