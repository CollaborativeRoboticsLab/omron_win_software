#!/bin/sh
set -eu

bootstrap_dir="${WINEPREFIX:-/wine}/.omron-bootstrap"
dotnet_marker="$bootstrap_dir/dotnet48"
dotnet6_marker="$bootstrap_dir/dotnet6-runtime"
ui_marker="$bootstrap_dir/ui-runtime"
dotnet6_version="6.0.36"
aspnetcore_runtime_url="https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/${dotnet6_version}/aspnetcore-runtime-${dotnet6_version}-win-x64.exe"
windowsdesktop_runtime_url="https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/${dotnet6_version}/windowsdesktop-runtime-${dotnet6_version}-win-x64.exe"

prefix_is_initialized() {
    [ -f "${WINEPREFIX:-/wine}/system.reg" ] || [ -f "${WINEPREFIX:-/wine}/user.reg" ]
}

prefix_is_win64() {
    [ -d "${WINEPREFIX:-/wine}/drive_c/windows/syswow64" ]
}

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

download_file() {
    url="$1"
    destination="$2"

    if [ -f "$destination" ]; then
        return
    fi

    curl -fL "$url" -o "$destination"
}

install_windows_runtime() {
    installer_path="$1"

    run_with_display "$wine_cmd" "$installer_path" /install /quiet /norestart
}

ensure_tmflow_ui_prereqs() {
    if [ -f "$ui_marker" ]; then
        return
    fi

    echo "Installing Windows fonts and UI rendering fixes for TMFlow" >&2
    run_with_display winetricks -q corefonts tahoma gdiplus fontsmooth=rgb renderer=gdi

    touch "$ui_marker"
}

ensure_tmflow_prereqs() {
    if prefix_is_initialized && ! prefix_is_win64; then
        echo "TMFlow now requires a 64-bit Wine prefix because the packaged installer is TMSetup64.exe" >&2
        echo "Remove the old TMFlow Wine volume and try again:" >&2
        echo "  docker compose -f compose.tmflow.yaml down" >&2
        echo "  docker volume rm omron_win_software_tmflow-wine" >&2
        exit 65
    fi

    if ! command -v winetricks >/dev/null 2>&1; then
        echo "winetricks is required to install .NET Framework for TMFlow" >&2
        exit 127
    fi

    mkdir -p "$bootstrap_dir"

    if ! prefix_is_initialized; then
        echo "Preparing Wine prefix for TMFlow" >&2
        run_with_display wineboot -u
    fi

    if [ ! -f "$dotnet_marker" ]; then
        echo "Installing .NET Framework 4.8 for TMFlow; this can take several minutes on first run" >&2
        run_with_display winetricks -q dotnet48

        touch "$dotnet_marker"
    fi

    if [ ! -f "$dotnet6_marker" ]; then
        aspnetcore_installer="$bootstrap_dir/aspnetcore-runtime-${dotnet6_version}-win-x64.exe"
        windowsdesktop_installer="$bootstrap_dir/windowsdesktop-runtime-${dotnet6_version}-win-x64.exe"

        echo "Downloading .NET 6 x64 runtimes required by installed TMFlow" >&2
        download_file "$aspnetcore_runtime_url" "$aspnetcore_installer"
        download_file "$windowsdesktop_runtime_url" "$windowsdesktop_installer"

        echo "Installing ASP.NET Core Runtime ${dotnet6_version} for TMFlow" >&2
        install_windows_runtime "$aspnetcore_installer"

        echo "Installing Windows Desktop Runtime ${dotnet6_version} for TMFlow" >&2
        install_windows_runtime "$windowsdesktop_installer"

        touch "$dotnet6_marker"
    fi

    ensure_tmflow_ui_prereqs
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