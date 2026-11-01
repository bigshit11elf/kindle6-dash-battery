#!/bin/sh
# PW2: disable frontlight via powerd and direct hardware sysfs interface.
LIGHT=/sys/devices/system/fl_tps6116x/fl_tps6116x0/fl_intensity
lipc-set-prop com.lab126.powerd flIntensity 0 >/dev/null 2>&1 || :
if [ -w "$LIGHT" ]; then
    printf '0' > "$LIGHT" || exit 1
else
    echo "Frontlight: $LIGHT unavailable" >&2
    exit 1
fi
