#!/usr/bin/env bash

set -u
set -o pipefail

URLS=(
    "http://127.0.0.1:8000/"
    "http://127.0.0.1:8080/"
)

FAILED=0

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
        "$url"
    then
        log "OK" "$url"
        return 0
    else
        log "ERROR" "$url"
        return 1
    fi
}

for url in "${URLS[@]}"; do
    if ! check_http "$url"; then
        FAILED=$((FAILED + 1))
    fi
done

log "INFO" "Failed checks: $FAILED"

if (( FAILED > 0 )); then
    exit 1
fi

exit 0
