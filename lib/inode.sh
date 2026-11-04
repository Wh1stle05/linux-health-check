#!/usr/bin/env bash

evaluate_inode() {
    local usage="${1:-}"
    local threshold="${2:-85}"
    local value

    if [[ ! "$usage" =~ ^[0-9]{1,3}$ ]]; then
        echo "[ERROR] Invalid inode usage"
        return 2
    fi

    if [[ ! "$threshold" =~ ^[0-9]{1,3}$ ]]; then
        echo "[ERROR] Invalid threshold"
        return 2
    fi

    value=$((10#$usage))

    if (( value > 100 || 10#$threshold > 100 )); then
        echo "[ERROR] Value out of range"
        return 2
    fi

    if (( value >= 10#$threshold )); then
        echo "[WARN] Inode usage: ${value}%"
        return 1
    fi

    echo "[OK] Inode usage: ${value}%"
    return 0
}


check_inode() {
    local iusage

    if ! iusage=$(df -i / | awk 'NR==2 {
        gsub(/%/, "", $5)
        print $5
    }'); then
        log "ERROR" "Inode collection failed"
        return 2
    fi

    evaluate_inode "$iusage" "$INODE_THRESHOLD"
}