#!/usr/bin/env bash
# Checks are invoked indirectly by run_check.
# shellcheck disable=SC2329

set -u
set -o pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/inode.sh
source "$SCRIPT_DIR/lib/inode.sh"

HTTP_URL="${1:-http://127.0.0.1:8000/}"
DISK_THRESHOLD=85
MEMORY_THRESHOLD=15
INODE_THRESHOLD=75

OK=0
WARN=0
ERRORS=0

log() {
    local level="$1"
    local message="$2"

    printf '[%s] [%s] %s\n' \
        "$(date '+%F %T')" \
        "$level" \
        "$message"
}

check_http() {
    local url="$1"

    if curl -fsS \
        --connect-timeout 2 \
        --max-time 5 \
        --output /dev/null \
        "$url"; then

        log "OK" "HTTP available: $url"
        return 0
    fi

    log "WARN" "HTTP unavailable: $url"
    return 1
}



check_disk() {
    local usage

    if ! usage=$(df -P / | awk 'NR==2 {
        gsub(/%/, "", $5)
        print $5
    }'); then
        log "ERROR" "Disk collection failed"
        return 2
    fi

    if [[ ! "$usage" =~ ^[0-9]+$ ]]; then
        log "ERROR" "Invalid disk usage"
        return 2
    fi

    if (( 10#$usage > 100 )); then
        log "ERROR" "Disk usage out of range"
        return 2
    fi

    if (( 10#$usage >= DISK_THRESHOLD )); then
        log "WARN" "Disk usage: ${usage}%"
        return 1
    fi

    log "OK" "Disk usage: ${usage}%"
    return 0
}

check_memory() {
    local total available
    local total_num available_num available_pct

    if ! total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo); then
        log "ERROR" "Cannot read MemTotal"
        return 2
    fi

    if ! available=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo); then
        log "ERROR" "Cannot read MemAvailable"
        return 2
    fi

    if [[ ! "$total" =~ ^[0-9]+$ ||
          ! "$available" =~ ^[0-9]+$ ]]; then
        log "ERROR" "Invalid memory data"
        return 2
    fi

    total_num=$((10#$total))
    available_num=$((10#$available))

    if (( total_num == 0 ||
          available_num > total_num )); then
        log "ERROR" "Invalid memory range"
        return 2
    fi

    available_pct=$((available_num * 100 / total_num))

    if (( available_num * 100 < total_num * MEMORY_THRESHOLD )); then
        log "WARN" "Available memory: ${available_pct}%"
        return 1
    fi

    log "OK" "Available memory: ${available_pct}%"
    return 0
}

run_check() {
    local name="$1"
    shift

    local func="$1"
    local status

    if ! declare -F "$func" >/dev/null; then
        log "ERROR" "$name function missing"
        ERRORS=$((ERRORS + 1))
        return 0
    fi

    if "$@"; then
        status=0
    else
        status=$?
    fi

    case "$status" in
        0)
            OK=$((OK + 1))
            ;;
        1)
            WARN=$((WARN + 1))
            ;;
        *)
            ERRORS=$((ERRORS + 1))
            ;;
    esac
}

run_check "HTTP" check_http "$HTTP_URL"
run_check "Disk" check_disk
run_check "Memory" check_memory
run_check "Inode" check_inode

printf '\nSummary: OK=%d WARN=%d ERROR=%d\n' \
    "$OK" "$WARN" "$ERRORS"

if (( ERRORS > 0 )); then
    exit 2
elif (( WARN > 0 )); then
    exit 1
fi

exit 0
