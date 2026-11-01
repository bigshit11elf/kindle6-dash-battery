#!/bin/sh
# Stop the long-running dashboard process (does not restore Kindle GUI).
pkill -f '/mnt/us/dashboard/dash.sh' 2>/dev/null || :
