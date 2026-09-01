# Karabo workshop services

This Compose project starts RabbitMQ, InfluxDB, Grafana, and an x86_64 Ubuntu
24.04 Karabo environment.

If you use `docker` instead of `podman`, simply replace `podman` with `docker`
in all commands listed below.

Start everything with:

```sh
podman compose up --build
```

The `karabo` service is intentionally pinned to `linux/amd64`, including on
Apple Silicon. Its first start persists a Karabo installation in the
`karabo-installation` volume and runs:

```sh
karabo-activate --init-to /opt/karabo/framework --backbone \\
  --broker-host amqp://xfel:karabo@rabbitmq:5672 --broker-topic karabo \\
  --influx-db tcp://influxdb:8086
```

On each start, its entrypoint sources `/opt/karabo/framework/activate`, runs
`karabo-start`, and then starts its configured command. The broker is therefore
available at `rabbitmq:5672` inside the container, using the `xfel` / `karabo`
credentials; InfluxDB is at `influxdb:8086`.
The Karabo GUI server is published on host port `44444`.

## Host GUI

Install the Karabo GUI on the host separately from the container, for example
in a virtual environment:

```sh
python3 -m venv .venv-karabo-gui
source .venv-karabo-gui/bin/activate
pip install karabo.gui
```

Or create and activate a Conda environment, then run `pip install karabo.gui`:

```sh
conda create -n karabo-gui python=3.12
conda activate karabo-gui
pip install karabo.gui
```

## Developing in the container

Keep the services running, then open an interactive, activated shell in the
Karabo container:

```sh
podman compose exec karabo bash
```

The shell sources `/opt/karabo/framework/activate` automatically. Your work is
inside the container unless you explicitly mount a host directory in
`compose.yaml`.

### VS Code Remote Development

Install VS Code's **Dev Containers** extension, start the Compose project, and
then run **Dev Containers: Attach to Running Container...** from the Command
Palette. Select the `karabo` container and open `/opt/karabo/framework` as the
workspace. VS Code installs its server in the container and its integrated
terminal uses the activated shell described above.

To use Podman with the Dev Containers extension, open VS Code **Settings**
(`Cmd+,` on macOS), search for **Dev Containers: Docker Path**, and set it to
`podman`. Reload VS Code, then attach to the same running `karabo` container.

If VS Code connects but its terminal never opens, run **Dev Containers: Open
Named Configuration File** from the Command Palette, select `karabo`, and add:

```json
{
  "userEnvProbe": "none"
}
```

Reattach to the container. This bypasses VS Code's login-shell environment
probe; terminals still source `/opt/karabo/framework/activate` via `.bashrc`.

## Podman on Apple Silicon

Podman on macOS uses a Linux virtual machine. On Apple Silicon, create an
Apple Hypervisor-backed machine with Rosetta support (enabled by default) so it
can emulate x86_64 Linux binaries:

```sh
podman machine init --provider applehv --now
podman run --rm --platform linux/amd64 alpine uname -m
```

The verification command should print `x86_64`. Then use Podman's Compose
provider to start this project:

```sh
podman compose up --build
```

If you already have a Podman machine that was not created with the Apple
Hypervisor provider, create a new `applehv` machine (or recreate the existing
one) before running the project. The `linux/amd64` platform in `compose.yaml`
selects the x86_64 image; emulation is slower than running a native image.

### Memory for Karabo and VS Code

Karabo's services and the x86_64-emulated VS Code Server need more memory than
Podman's common 2 GiB default. Allocate at least 4, better 8 GiB
to the Podman machine:

```sh
podman machine stop
podman machine set --memory 8192
podman machine start
podman compose up -d
```

Stopping the machine temporarily stops its containers but does not remove their
images or volumes. If VS Code reports a successful container connection and its
terminal then hangs or disconnects, look for `Killed` or `ECONNRESET` in the
Dev Containers log; these indicate that the VM ran out of memory.

### Repairing a locked Karabo service volume

If Karabo exits with `svok: fatal: unable to chdir .../.svscan: access denied`
or a `PermissionError` for `var/service`, Podman has retained an SELinux label
from a previous Karabo container. The Karabo service disables SELinux labeling
for its named installation volume, so the existing installation can be
retained. Recreate only the Karabo container:

```sh
podman compose rm -sf karabo
podman compose up -d karabo
```

Do not remove `karabo-installation`; it contains the activated Karabo
environment. The recreated container can access it without relabeling.
