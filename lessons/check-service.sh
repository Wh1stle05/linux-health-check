#!/usr/bin/env bash

set -u

URL="${1:-http://127.0.0.1:8000/}"

echo "Checking: $URL"

if curl \
  --fail \
  --silent \
  --show-error \
  --max-time 5 \
  --output /dev/null \
  "$URL"
then
    echo "[OK] Service available"
    exit 0
else
    echo "[ERROR] Service unavailable"
    exit 1
fi
