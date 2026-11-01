#!/bin/sh
# Kindle Paperwhite 2: background dashboard with continuous log rotation.
DIR=/mnt/us/dashboard
ENV_FILE="$DIR/local/env.sh"
[ -f "$ENV_FILE" ] && . "$ENV_FILE"

if [ "${DEBUG:-false}" = true ]; then
    exec /bin/sh "$DIR/dash.sh"
fi

mkdir -p "$DIR/logs" || exit 1
# Output goes to a pipe; log-writer opens the destination afresh for every line.
# This avoids holding an old log inode open across rotations.
( /bin/sh "$DIR/dash.sh" 2>&1 | /bin/sh "$DIR/log-writer.sh" ) </dev/null >/dev/null 2>&1 &
