#!/usr/bin/env bash

set -u
set -o pipefail

log() {
    local level="$1"
    local message="$2"

    printf '[%s] %s\n' "$level" "$message"
}

check_disk() {
    local disk_usage

    # 1. 获取磁盘使用率
    if ! disk_usage=$(df -P / | awk 'NR==2 {
        gsub(/%/, "", $5)
        print $5
    }'); then
        log "ERROR" "Failed to collect disk usage"
        return 1
    fi

    # 2. 验证提取结果
    if [[ ! "$disk_usage" =~ ^[0-9]+$ ]]; then
        log "ERROR" "Invalid disk usage: $disk_usage"
        return 1
    fi

    # 3. 判断数值范围
    if (( 10#$disk_usage > 100 )); then
        log "ERROR" "Disk usage out of range"
        return 1
    fi

    # 4. 检查阈值
    if (( 10#$disk_usage >= 85 )); then
        log "WARN" "Disk usage: ${disk_usage}%"
        return 1
    fi

    log "OK" "Disk usage: ${disk_usage}%"
    return 0
}

check_disk
exit $?