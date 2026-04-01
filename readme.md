# Omron Windows Software Container

These images install Wine and copy Windows installers or executables from `exe/` into the container.

The project builds two separate images:

- `ghcr.io/collaborativeroboticslab/omron_win_software-mobileplanner`
- `ghcr.io/collaborativeroboticslab/omron_win_software-tmflow`

## Image Tags

Current image tags by software version:

- `ghcr.io/collaborativeroboticslab/omron_win_software-mobileplanner:latest`
- `ghcr.io/collaborativeroboticslab/omron_win_software-mobileplanner:mobileplanner_8.1.9`
- `ghcr.io/collaborativeroboticslab/omron_win_software-tmflow:latest`
- `ghcr.io/collaborativeroboticslab/omron_win_software-tmflow:v2.22.4200`

The MobilePlanner version tag is derived from the local file `exe/MobilePlanner_8.1.9.exe`.
The TMFlow version tag is currently derived from the configured remote archive name `V2.22.4200.zip` until a local `TMFlow*.exe` is added.

Each image defaults to its own launcher, and the launcher searches `/opt/omron/exe` for the first matching executable and runs it through Wine.

## Build

```sh
docker build \
	--build-arg DEFAULT_APP=MobilePlanner \
	-t ghcr.io/collaborativeroboticslab/omron_win_software-mobileplanner:latest .

docker build \
	--build-arg DEFAULT_APP=TMFlow \
	--build-arg TMFLOW_URL='https://example.invalid/TMFlow.zip' \
	-t ghcr.io/collaborativeroboticslab/omron_win_software-tmflow:latest .
```

## Run With Compose

Start MobilePlanner:

```sh
docker compose -f compose.mobileplanner.yaml up
```

Start TMFlow:

```sh
TMFLOW_URL='https://example.invalid/TMFlow.zip' docker compose -f compose.tmflow.yaml up
```

## Remote TMFlow Download

`TMFlow` is large enough that it is usually better not to store it in the repository.

The Docker build supports an optional `TMFLOW_URL` build argument. When provided, the image downloads the remote archive and extracts it under `/opt/omron/exe` during build time.

```sh
docker build \
	--build-arg DEFAULT_APP=TMFlow \
	--build-arg TMFLOW_URL='https://example.invalid/TMFlow.zip' \
	-t ghcr.io/collaborativeroboticslab/omron_win_software-tmflow:latest .
```

The GitHub workflow reads `TMFLOW_URL` from `secrets.TMFLOW_URL` first, then from `vars.TMFLOW_URL`.

Pushes to `main` build only the MobilePlanner image. The TMFlow image builds only on `workflow_dispatch`, and only when a local `TMFlow*.exe` exists or `TMFLOW_URL` is configured.

If no matching executable is present for the selected launcher, the container exits with a clear error.
