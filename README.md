# Omron Windows Software Container

These images install Wine and copy Windows installers or executables from `exe/` into the container.

The project builds two separate images:

- `ghcr.io/collaborativeroboticslab/omron_win_software-mobileplanner`
- `ghcr.io/collaborativeroboticslab/omron_win_software-tmflow`

## Available Software Versions

| Software | Version | Source |
|----------|---------|--------|
| MobilePlanner | ![MobilePlanner 8.1.9](https://img.shields.io/badge/MobilePlanner-8.1.9-0a7bbb) | Local `exe/MobilePlanner_8.1.9.exe` |
| TMFlow | ![TMFlow 2.22.4200](https://img.shields.io/badge/TMFlow-2.22.4200-2f855a) | Remote archive `V2.22.4200.zip` |

Each image defaults to its own launcher, and the launcher searches `/opt/omron/exe` for the first matching executable and runs it through Wine. When `DISPLAY` and the X11 socket are available, the launcher uses the host X server; otherwise it falls back to an internal Xvfb display.

For MobilePlanner, the first run may open the installer from `exe/`. After installation completes, later runs launch the installed application from the persistent Wine prefix automatically.

For TMFlow, the first run may open either `TMFlow*.exe` or `TMSetup*.exe`, depending on what was packaged into the image. Before that happens, the launcher bootstraps `.NET Framework 4.8` into the persistent Wine prefix because TMFlow requires `.NET Framework 4.5.2` or newer. The current packaged media is `TMSetup64.exe`, so TMFlow now uses a 64-bit Wine prefix. After installation completes, later runs launch the installed `TMFlow.exe` from the persistent Wine prefix automatically.

## Run With Compose

The compose files are runtime-only and pull the published GHCR images. They do not build local images.

Start MobilePlanner:

```sh
xhost +local:root
docker compose -f compose.mobileplanner.yaml pull
docker compose -f compose.mobileplanner.yaml up
```

Start TMFlow:

```sh
xhost +local:root
docker compose -f compose.tmflow.yaml pull
docker compose -f compose.tmflow.yaml up
```

The compose files mount the host X11 socket from `/tmp/.X11-unix`, pass through `DISPLAY`, mount `${HOME}/.Xauthority` into the container, and persist the Wine prefix in a named Docker volume.

When you run `docker compose up`, the command stays attached to the GUI process by design. A successful start should now print `Using host X11 display: ...` before the application window appears on the host desktop.

If you need to reset MobilePlanner and rerun the installer from scratch, remove the named Docker volume for its Wine prefix:

```sh
docker compose -f compose.mobileplanner.yaml down
docker volume rm omron_win_software_mobileplanner-wine
```

To reset TMFlow and rerun its installer from scratch:

```sh
docker compose -f compose.tmflow.yaml down
docker volume rm omron_win_software_tmflow-wine
```

If TMFlow was started before the .NET bootstrap or before the switch to a 64-bit Wine prefix, reset the TMFlow Wine volume once so the prefix can be recreated cleanly with the required runtime and architecture.

## TMFlow Source

The GitHub workflow reads `TMFLOW_URL` from `secrets.TMFLOW_URL` first, then from `vars.TMFLOW_URL`.

Pushes to `main` build only the MobilePlanner image. The TMFlow image builds only on `workflow_dispatch`, and only when a local `TMFlow*.exe` exists or `TMFLOW_URL` is configured.

When running from Compose, the published TMFlow image may launch either `TMFlow*.exe` or `TMSetup*.exe`, depending on what the downloaded archive contains.

If no matching executable is present for the selected launcher, the container exits with a clear error.
