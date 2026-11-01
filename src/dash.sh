#!/usr/bin/env sh
# Kindle Paperwhite 2 (6. Generation) – Dashboard
# Adapted from pascalw/kindle-dash; RTC wakeup tested on PW2.

DEBUG=${DEBUG:-false}
[ "$DEBUG" = true ] && set -x

DIR="/mnt/us/dashboard"
DASH_PNG="$DIR/dash.png"
FETCH_DASHBOARD_CMD="$DIR/local/fetch-dashboard.sh"
LOW_BATTERY_CMD="$DIR/local/low-battery.sh"
REFRESH_SCHEDULE=${REFRESH_SCHEDULE:-"*/5 * * * *"}
FULL_DISPLAY_REFRESH_RATE=${FULL_DISPLAY_REFRESH_RATE:-0}
LOW_BATTERY_REPORTING=${LOW_BATTERY_REPORTING:-false}
LOW_BATTERY_THRESHOLD_PERCENT=${LOW_BATTERY_THRESHOLD_PERCENT:-10}
LIGHT_OFF="$DIR/light-off.sh"
num_refresh=0

init() {
    if [ -z "$TIMEZONE" ] || [ -z "$REFRESH_SCHEDULE" ]; then
        echo "Missing TIMEZONE or REFRESH_SCHEDULE" >&2
        exit 1
    fi
    echo "Starting Paperwhite 2 dashboard: $REFRESH_SCHEDULE"
    # WARNING: stopping the UI can terminate a library-launched script.
    /sbin/initctl stop framework >/dev/null 2>&1 || true
    /sbin/initctl stop lab126_gui >/dev/null 2>&1 || true
    /sbin/initctl stop webreader >/dev/null 2>&1 || true
    sleep 2
    if [ -w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
        echo powersave > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor || true
    fi
    lipc-set-prop com.lab126.powerd preventScreenSaver 1 || true
    /bin/sh "$LIGHT_OFF" || echo "Frontlight: could not switch off" >&2
}

refresh_dashboard() {
    /bin/sh "$LIGHT_OFF" || echo "Frontlight: switch-off failed before refresh" >&2
    echo "Refreshing dashboard: $(date)"
    "$DIR/wait-for-wifi.sh" "$WIFI_TEST_IP"
    "$FETCH_DASHBOARD_CMD" "$DASH_PNG"
    fetch_status=$?
    if [ "$fetch_status" -ne 0 ]; then
        echo "Download failed ($fetch_status); keeping previous image" >&2
        /bin/sh "$LIGHT_OFF" || :
        return 1
    fi
    if [ "$FULL_DISPLAY_REFRESH_RATE" -eq 0 ] || [ "$num_refresh" -ge "$FULL_DISPLAY_REFRESH_RATE" ]; then
        num_refresh=0
        echo "Full refresh"
        /usr/sbin/eips -f -g "$DASH_PNG"
    else
        echo "Partial refresh"
        /usr/sbin/eips -g "$DASH_PNG"
    fi
    num_refresh=$((num_refresh + 1))
    /bin/sh "$LIGHT_OFF" || echo "Frontlight: switch-off failed after refresh" >&2
}

log_battery_stats() {
    battery_level=$(gasgauge-info -c 2>/dev/null)
    echo "$(date) Battery level: $battery_level"
    if [ "$LOW_BATTERY_REPORTING" = true ]; then
        battery_level_numeric=${battery_level%\%}
        case "$battery_level_numeric" in
            ''|*[!0-9]*) return 0 ;;
        esac
        if [ "$battery_level_numeric" -le "$LOW_BATTERY_THRESHOLD_PERCENT" ]; then
            "$LOW_BATTERY_CMD" "$battery_level_numeric"
        fi
    fi
}

rtc_sleep() {
    duration=$1
    case "$duration" in
        ''|*[!0-9]*|0)
            echo "Invalid wake duration: $duration" >&2
            return 1 ;;
    esac
    /bin/sh "$LIGHT_OFF" || echo "Frontlight: switch-off failed before suspend" >&2
    if [ "$DEBUG" = true ]; then
        echo "DEBUG: sleep $duration (no suspend)"
        sleep "$duration"
        /bin/sh "$LIGHT_OFF" || :
        return 0
    fi
    echo "RTC: Sleeping for ${duration}s using rtcwake rtc1"
    sync
    rtcwake -d /dev/rtc1 -m mem -s "$duration"
    status=$?
    /bin/sh "$LIGHT_OFF" || echo "Frontlight: switch-off failed after wakeup" >&2
    echo "RTC: Resumed at $(date), status $status"
    return "$status"
}

main_loop() {
    while true; do
        log_battery_stats
        refresh_dashboard
        next_wakeup_secs=$("$DIR/next-wakeup" \
            --schedule="$REFRESH_SCHEDULE" --timezone="$TIMEZONE")
        case "$next_wakeup_secs" in
            ''|*[!0-9]*|0)
                echo "Invalid next wakeup: $next_wakeup_secs" >&2
                sleep 60
                continue ;;
        esac
        # Pause for E-Ink update to settle before suspending.
        sleep 2
        echo "Next wakeup in ${next_wakeup_secs}s"
        if ! rtc_sleep "$next_wakeup_secs"; then
            echo "RTC sleep failed; retrying in 60s" >&2
            sleep 60
        fi
    done
}

init
main_loop
