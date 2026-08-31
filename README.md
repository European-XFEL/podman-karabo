# Karabo workshop services

This Compose project starts RabbitMQ, InfluxDB, Grafana, and an x86_64 Ubuntu
24.04 Karabo environment.

If you use `docker` instead of `podmanc`, simply replace `podman` with `docker`
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

### Resetting a locked Karabo service volume

If Karabo exits with `svok: fatal: unable to chdir .../.svscan: access denied`
or a `PermissionError` for `var/service`, its persisted daemontools supervisor
state belongs to a previous Podman container context. Remove only the Karabo
container and installation volume, then initialize it again:

```sh
podman rm -f karabo_workshop-karabo-1
podman volume rm karabo_workshop_karabo-installation
podman compose up --build -d karabo
```

This deletes the Karabo installation and service state, but preserves the
RabbitMQ, InfluxDB, and Grafana volumes.
