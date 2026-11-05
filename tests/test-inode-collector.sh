#!/usr/bin/env bash

set -u
set -o pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

INODE_THRESHOLD=75
FAILED=0

log() {
    printf '[%s] %s\n' "$1" "$2"
}

# shellcheck source=lib/inode.sh
source "$ROOT/lib/inode.sh"

# 只在当前测试脚本中模拟 df
df() {
    # 检查生产函数是否传入正确参数
    if [[ "$#" -ne 2 || "$1" != "-Pi" || "$2" != "/" ]]; then
        return 2
    fi

    case "$MOCK_DF_MODE" in
        ok)
            printf 'Filesystem Inodes IUsed IFree IUse%% Mounted\n'
            printf '/dev/test 1000 740 260 74%% /\n'
            ;;
        warn)
            printf 'Filesystem Inodes IUsed IFree IUse%% Mounted\n'
            printf '/dev/test 1000 750 250 75%% /\n'
            ;;
        invalid)
            printf 'Filesystem Inodes IUsed IFree IUse%% Mounted\n'
            printf '/dev/test 1000 500 500 abc%% /\n'
            ;;
        empty)
            printf 'Filesystem Inodes IUsed IFree IUse%% Mounted\n'
            ;;
        fail)
            return 42
            ;;
        *)
            return 2
            ;;
    esac

}

assert_check() {
    local mode="$1"
    local expected="$2"
    local actual output

    MOCK_DF_MODE="$mode"

    if output=$(check_inode); then
        actual=0
    else
        actual=$?
    fi

    if (( actual == expected )); then
        printf '[PASS] mode=%s expected=%d\n' \
            "$mode" "$expected"
    else
        printf '[FAIL] mode=%s expected=%d actual=%d\n' \
            "$mode" "$expected" "$actual"
        printf 'Output: %s\n' "$output"
        FAILED=$((FAILED + 1))
    fi
}

assert_check ok 0
assert_check warn 1
assert_check invalid 2
assert_check empty 2
assert_check fail 2

printf 'Failed tests: %d\n' "$FAILED"

if (( FAILED > 0 )); then
    exit 1
fi

exit 0
