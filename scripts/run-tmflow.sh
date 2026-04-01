#!/bin/sh
set -eu

app_path="$(find /opt/omron/exe -type f -iname 'TMFlow*.exe' | sort | head -n 1)"

if [ -z "$app_path" ]; then
    echo "No executable matching TMFlow*.exe was found in /opt/omron/exe" >&2
    exit 66
fi

exec xvfb-run -a wine "$app_path" "$@"