#!/bin/sh
set -eu

launcher_name="$(basename "$0")"

case "$launcher_name" in
    MobilePlanner)
        app_pattern='MobilePlanner*.exe'
        ;;
    TMFlow)
        app_pattern='TMFlow*.exe'
        ;;
    *)
        echo "Unsupported launcher: $launcher_name" >&2
        exit 64
        ;;
esac

app_path="$(find /opt/omron/exe -type f -iname "$app_pattern" | sort | head -n 1)"

if [ -z "$app_path" ]; then
    echo "No executable matching $app_pattern was found in /opt/omron/exe" >&2
    exit 66
fi

exec xvfb-run -a wine "$app_path" "$@"