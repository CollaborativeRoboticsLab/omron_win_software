#!/bin/sh
set -eu

resolve_wine() {
    for candidate in \
        "$(command -v wine 2>/dev/null || true)" \
        "$(command -v wine64 2>/dev/null || true)" \
        /usr/lib/wine/wine \
        /usr/lib/wine/wine64 \
        /usr/libexec/wine/wine \
        /usr/libexec/wine/wine64
    do
        if [ -n "$candidate" ] && [ -x "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    echo "Wine executable not found in the container" >&2
    exit 127
}

resolve_app_path() {
    for candidate in \
        "/wine/drive_c/Program Files/Omron/MobilePlanner 8.1/bin/MobilePlanner.exe" \
        "/wine/drive_c/Program Files (x86)/Omron/MobilePlanner 8.1/bin/MobilePlanner.exe"
    do
        if [ -f "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    find /wine/drive_c -type f -iname 'MobilePlanner.exe' 2>/dev/null | sort | head -n 1
}

app_path="$(resolve_app_path)"

if [ -n "$app_path" ]; then
    launch_mode="installed application"
else
    app_path="$(find /opt/omron/exe -type f -iname 'MobilePlanner*.exe' | sort | head -n 1)"
    launch_mode="setup executable"
fi

if [ -z "$app_path" ]; then
    echo "No installed MobilePlanner executable or setup EXE was found" >&2
    exit 66
fi

wine_cmd="$(resolve_wine)"

echo "Launching MobilePlanner ($launch_mode): $app_path" >&2
echo "Using Wine command: $wine_cmd" >&2
echo "DISPLAY=${DISPLAY:-unset} WINEPREFIX=${WINEPREFIX:-unset}" >&2

if [ -n "${DISPLAY:-}" ] && [ -d /tmp/.X11-unix ]; then
    echo "Using host X11 display: $DISPLAY" >&2
    exec "$wine_cmd" "$app_path" "$@"
fi

echo "Host X11 display unavailable; falling back to xvfb-run" >&2
exec xvfb-run -a "$wine_cmd" "$app_path" "$@"