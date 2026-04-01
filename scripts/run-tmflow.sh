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

app_path="$(find /opt/omron/exe -type f -iname 'TMFlow*.exe' | sort | head -n 1)"

if [ -z "$app_path" ]; then
    app_path="$(find /opt/omron/exe -type f -iname 'TMSetup*.exe' | sort | head -n 1)"
fi

if [ -z "$app_path" ]; then
    echo "No executable matching TMFlow*.exe or TMSetup*.exe was found in /opt/omron/exe" >&2
    exit 66
fi

wine_cmd="$(resolve_wine)"

echo "Launching TMFlow with executable: $app_path" >&2
echo "Using Wine command: $wine_cmd" >&2
echo "DISPLAY=${DISPLAY:-unset} WINEPREFIX=${WINEPREFIX:-unset}" >&2

exec xvfb-run -a "$wine_cmd" "$app_path" "$@"