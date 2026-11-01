#!/bin/sh
# Bounded on-device logs during the entire dashboard runtime.
DIR=/mnt/us/dashboard
LOG_DIR="$DIR/logs"
LOG="$LOG_DIR/dash.log"
OLD="$LOG_DIR/dash.log.1"
MAX_BYTES=${MAX_LOG_BYTES:-262144}
case "$MAX_BYTES" in ''|*[!0-9]*|0) MAX_BYTES=262144 ;; esac
mkdir -p "$LOG_DIR" || exit 1
while IFS= read -r line || [ -n "$line" ]; do
    # Include the next line in the limit; one unusually long line may exceed it.
    if [ -f "$LOG" ]; then
        current=$(wc -c < "$LOG" 2>/dev/null) || current=0
        case "$current" in ''|*[!0-9]*) current=0 ;; esac
        if [ "$current" -ge "$MAX_BYTES" ]; then
            rm -f "$OLD" || exit 1
            mv "$LOG" "$OLD" || exit 1
        fi
    fi
    printf '%s\n' "$line" >> "$LOG" || exit 1
done
