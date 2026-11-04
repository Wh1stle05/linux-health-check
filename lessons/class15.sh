#!/usr/bin/env bash

set -u
set -o pipefail

OK=0
WARN=0
ERRORS=0

check_http() {
    return 1
}

check_disk() {
    return 0
}

check_memory() {
    return 2
}

run_check() {
    local name="$1"
    shift

    local func="$1"
    local status

    # 确认检查函数已定义
    if ! declare -F "$func" > /dev/null; then
        printf '[ERROR] %s: function missing\n' "$name"
        ERRORS=$((ERRORS + 1))
        return 0
    fi

    # 执行检查，保留原始退出状态
    if "$@"; then
        status=0
    else
        status=$?
    fi

    case "$status" in
        0)
            printf '[OK] %s\n' "$name"
            OK=$((OK + 1))
            ;;
        1)
            printf '[WARN] %s\n' "$name"
            WARN=$((WARN + 1))
            ;;
        *)
            printf '[ERROR] %s: exit=%s\n' "$name" "$status"
            ERRORS=$((ERRORS + 1))
            ;;
    esac
}

run_check "HTTP" check_http
run_check "Disk" check_disk
run_check "Memory" check_memory

printf '\nSummary: OK=%d WARN=%d ERROR=%d\n' \
    "$OK" "$WARN" "$ERRORS"

if (( ERRORS > 0 )); then
    exit 2
elif (( WARN > 0 )); then
    exit 1
fi

exit 0