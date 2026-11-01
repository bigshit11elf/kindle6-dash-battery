#!/bin/sh
# Public defaults for Kindle Paperwhite 2 (PW2, 6th-generation Kindle).
# Put private values into local/env.private.sh (ignored by Git), or edit this
# file only on the Kindle. Do not commit real webhook URLs.
export WIFI_TEST_IP="${WIFI_TEST_IP:-1.1.1.1}"
[ -n "${REFRESH_SCHEDULE:-}" ] || REFRESH_SCHEDULE="*/10 * * * *"
export REFRESH_SCHEDULE
export TIMEZONE="${TIMEZONE:-Europe/Berlin}"
export FULL_DISPLAY_REFRESH_RATE="${FULL_DISPLAY_REFRESH_RATE:-4}"
export LOW_BATTERY_REPORTING="${LOW_BATTERY_REPORTING:-false}"
export LOW_BATTERY_THRESHOLD_PERCENT="${LOW_BATTERY_THRESHOLD_PERCENT:-10}"
export MAX_LOG_BYTES="${MAX_LOG_BYTES:-262144}"
export DASHBOARD_URL="${DASHBOARD_URL:-http://HOME_ASSISTANT_IP:8123/api/eink_dashboard/ENTRY_ID/image.png}"
export BATTERY_WEBHOOK_URL="${BATTERY_WEBHOOK_URL:-}"
if [ -f /mnt/us/dashboard/local/env.private.sh ]; then
  . /mnt/us/dashboard/local/env.private.sh
fi
