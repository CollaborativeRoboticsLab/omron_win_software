#!/bin/sh
set -eu

bootstrap_dir="${WINEPREFIX:-/wine}/.omron-bootstrap"
dotnet_marker="$bootstrap_dir/dotnet48"

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

run_with_display() {
    if [ -n "${DISPLAY:-}" ] && [ -d /tmp/.X11-unix ]; then
        "$@"
        return
    fi

    xvfb-run -a "$@"
}

ensure_tmflow_prereqs() {
    if [ -f "$dotnet_marker" ]; then
        return
    fi

    if ! command -v winetricks >/dev/null 2>&1; then
        echo "winetricks is required to install .NET Framework for TMFlow" >&2
        exit 127
    fi

    mkdir -p "$bootstrap_dir"

    echo "Preparing Wine prefix for TMFlow" >&2
    run_with_display wineboot -u

    echo "Installing .NET Framework 4.8 for TMFlow; this can take several minutes on first run" >&2
    run_with_display winetricks -q dotnet48

    touch "$dotnet_marker"
}

resolve_app_path() {
    find /wine/drive_c -type f -iname 'TMFlow.exe' 2>/dev/null | sort | head -n 1
}

app_path="$(resolve_app_path)"

if [ -n "$app_path" ]; then
    launch_mode="installed application"
else
    app_path="$(find /opt/omron/exe -type f -iname 'TMFlow*.exe' | sort | head -n 1)"
    launch_mode="setup executable"
fi

if [ -z "$app_path" ]; then
    app_path="$(find /opt/omron/exe -type f -iname 'TMSetup*.exe' | sort | head -n 1)"
    launch_mode="setup executable"
fi

if [ -z "$app_path" ]; then
    echo "No installed TMFlow executable or setup EXE was found" >&2
    exit 66
fi

wine_cmd="$(resolve_wine)"

ensure_tmflow_prereqs

echo "Launching TMFlow ($launch_mode): $app_path" >&2
echo "Using Wine command: $wine_cmd" >&2
echo "DISPLAY=${DISPLAY:-unset} WINEPREFIX=${WINEPREFIX:-unset}" >&2

if [ -n "${DISPLAY:-}" ] && [ -d /tmp/.X11-unix ]; then
    echo "Using host X11 display: $DISPLAY" >&2
    exec "$wine_cmd" "$app_path" "$@"
fi

echo "Host X11 display unavailable; falling back to xvfb-run" >&2
exec xvfb-run -a "$wine_cmd" "$app_path" "$@"