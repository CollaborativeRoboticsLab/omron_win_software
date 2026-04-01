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

Each image defaults to its own launcher, and the launcher searches `/opt/omron/exe` for the first matching executable and runs it through Wine.

## Build

```sh
docker build \
	-f Dockerfile.mobileplanner \
	-t ghcr.io/collaborativeroboticslab/omron_win_software-mobileplanner:latest .

docker build \
	-f Dockerfile.tmflow \
	--build-arg TMFLOW_URL='https://example.invalid/TMFlow.zip' \
	-t ghcr.io/collaborativeroboticslab/omron_win_software-tmflow:latest .
```

## Run With Compose

Start MobilePlanner:

```sh
xhost +local:docker
docker compose -f compose.mobileplanner.yaml up
```

Start TMFlow:

```sh
xhost +local:docker
TMFLOW_URL='https://example.invalid/TMFlow.zip' docker compose -f compose.tmflow.yaml up
```

The compose files mount the host X11 socket from `/tmp/.X11-unix`, pass through `DISPLAY`, mount `${HOME}/.Xauthority` into the container, and persist the Wine prefix in a named Docker volume.

## Remote TMFlow Download

`TMFlow` is large enough that it is usually better not to store it in the repository.

The Docker build supports an optional `TMFLOW_URL` build argument. When provided, the image downloads the remote archive and extracts it under `/opt/omron/exe` during build time.

```sh
docker build \
	-f Dockerfile.tmflow \
	--build-arg TMFLOW_URL='https://example.invalid/TMFlow.zip' \
	-t ghcr.io/collaborativeroboticslab/omron_win_software-tmflow:latest .
```

The GitHub workflow reads `TMFLOW_URL` from `secrets.TMFLOW_URL` first, then from `vars.TMFLOW_URL`.

Pushes to `main` build only the MobilePlanner image. The TMFlow image builds only on `workflow_dispatch`, and only when a local `TMFlow*.exe` exists or `TMFLOW_URL` is configured.

If no matching executable is present for the selected launcher, the container exits with a clear error.
