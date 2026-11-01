
#!/usr/bin/env sh

# Kindle Dash - Home Assistant E-Ink dashboard
# Optional battery reporting via Home Assistant webhook.
#
# Configuration is loaded from local/env.sh
# by kindle-dash/start.sh.
#
# No credentials or personal URLs are hardcoded.

DIR="$(dirname "$0")"
XH="$DIR/../xh"

# 1. Download dashboard image

if [ -z "$DASHBOARD_URL" ]; then
    echo "Dashboard: DASHBOARD_URL not configured" >&2
    exit 1
fi

echo "Dashboard: Download started"

"$XH" --ignore-stdin -d -q -o "$1" get \
    "$DASHBOARD_URL"

image_status=$?

if [ "$image_status" -eq 0 ]; then
    echo "Dashboard: PNG downloaded"
else
    echo "Dashboard: Download failed ($image_status)" >&2
fi

# 2. Optional battery reporting

if [ -n "$BATTERY_WEBHOOK_URL" ]; then

    battery=$(gasgauge-info -c 2>/dev/null)
    battery=${battery%\%}

    case "$battery" in
        ''|*[!0-9]*)
            echo "Battery: Invalid value [$battery]" >&2
            ;;

        *)
            if [ "$battery" -le 100 ]; then

                echo "Battery: Sending ${battery}%"

                "$XH" --ignore-stdin --timeout 5 -q POST \
                    "$BATTERY_WEBHOOK_URL" \
                    battery:="$battery"

                webhook_status=$?

                if [ "$webhook_status" -eq 0 ]; then
                    echo "Battery: Webhook sent (${battery}%)"
                else
                    echo "Battery: Webhook failed ($webhook_status)" >&2
                fi

            else
                echo "Battery: Value out of range" >&2
            fi
            ;;
    esac

fi

exit "$image_status"
