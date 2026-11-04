#!/usr/bin/env bash

set -u

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/inode.sh
source "$ROOT/lib/inode.sh"

FAILED=0

assert_status() {
    local input="$1"
    local expected="$2"
    local threshold="${3:-85}"
    local actual

    if evaluate_inode "$input" "$threshold" >/dev/null; then
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
assert_status "74" 0 75
assert_status "75" 1 75
assert_status "50" 2 101
assert_status "50" 2 abc

printf 'Failed tests: %d\n' "$FAILED"

if (( FAILED > 0 )); then
    exit 1
fi

exit 0
