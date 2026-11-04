#!/usr/bin/env bash

set -u

INODE_THRESHOLD=85

evaluate_inode() {
    local usage="$1"
    local value

    # 检查格式
    if [[ ! "$usage" =~ ^[0-9]{1,3}$ ]]; then
        echo "[ERROR] Invalid inode usage"
        return 2
    fi

    # 转成十进制
    value=$((10#$usage))

    # 检查范围
    if (( value > 100 )); then
        echo "[ERROR] Inode usage out of range"
        return 2
    fi

    # 检查阈值
    if (( value >= INODE_THRESHOLD )); then
        echo "[WARN] Inode usage: ${value}%"
        return 1
    fi

    echo "[OK] Inode usage: ${value}%"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    evaluate_inode "${1:-}"
fi