#!/usr/bin/env bash

set -u
set -o pipefail

log() {
    local level="$1"
    local message="$2"

    printf '[%s] %s\n' "$level" "$message"
}

check_memory() {
    local total available available_pct

    # 1. 获取 total 和 available
    total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo) 
    available=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
    # 2. 验证数据
    if [[ ! "$total" =~ ^[0-9]+$ ]]; then
        log "ERROR" "Invalid TotalMem Quantity"
        return 1
    fi

    if [[ ! "$available" =~ ^[0-9]+$ ]]; then
        log "ERROR" "Invalid AvaliableMem Quantity"
        return 1
    fi

    if (("$total" = 0));then
        log "ERROR" "TotalMem Quantity Cannot Be Zero"
        return 1
    fi
    # 3. 计算百分比
    available_pct=$(( "$available" * 100/ "$total" ))
    # 4. 判断阈值并返回
    if ((10#$available_pct <= 15));then
        log "WARN" "Memory Usage High"
        return 1
    else
        log "OK" "Memory Usage Health"
        return 0
    fi
}

check_memory
exit $?
