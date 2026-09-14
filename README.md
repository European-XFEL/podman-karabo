# Podman Karabo

This repository bundles containers to run a Karabo environment on an x86_64
Ubuntu 24.04 with its necessary prerequisites (RabbitMQ, InfluxDB, Grafana)
on various operating systems.
It should work on any Linux system, on macOS (even Apple Silicon), and on
Windows 11.

The system needs `podman` to be installed to run Linux containers.
If `podman` does not work for you on Linux, you can alteratively use `docker`. Note
that you might need root permissions or your username to be added to the `docker` group
in order to start `docker` containers.

Windows and macOS specific guides for `podman` can be found further below.

# Karabo Workshop Environment Setup

Checkout this repository and, within its root directory, follow these steps:

Start everything with:

```sh
podman compose up --build
```

If you use `docker` instead of `podman`, run instead:

```sh
docker-compose build
docker-compose up
```

The `karabo` service is intentionally pinned to `linux/amd64`, including on
Apple Silicon. Its first start persists a Karabo installation in the
`karabo-installation` volume and runs:

```sh
karabo-activate --init-to /home/karabouser/framework --backbone \\
  --broker-host amqp://xfel:karabo@rabbitmq:5672 --broker-topic karabo \\
  --influx-db tcp://influxdb:8086
```

On each start, its entrypoint sources `/home/karabouser/framework/activate`, runs
`karabo-start`, and then starts its configured command. The broker is therefore
available at `rabbitmq:5672` inside the container, using the `xfel` / `karabo`
credentials; InfluxDB is at `influxdb:8086`.
The Karabo GUI server is published on host port `44444`.

## Host GUI

The Karabo GUI needs to be installed on the host separately from the container. For
this workshop (and for Windows in general), we recommend downloading and installing
a complete Karabo GUI bundle that matches your operating system from

https://syncandshare.xfel.eu/index.php/s/tcdSdqLGKbqYoWb

In Linux (and possibly MacOS), you'll have to give the file writing permissions:

```sh
chmod a+x karabo-gui
```

### Other ways to install the GUI

As an alternative way of installing the Karabo GUI, you can install it on a Python virtual environment (Python 3.12 required):

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

## Developing in the Container

Keep the services running, then, in another shell of your host machine,
open an interactive shell in the Karabo container
(after `cd` to the directory with `podman.yaml`) via: 

```sh
podman compose exec karabo bash
```

(or replace `podman compose` with `docker-compose`).

The shell sources `/home/karabouser/framework/activate` automatically. Your work is
inside the container unless you explicitly mount a host directory in
`compose.yaml`.

Note that terminal editors like `emacs`, `nano` and `vim` are available in
the machine.

The Karabo environment is activated in this `bash` shell.
You can check that and see which Karabo servers are available via

```sh
karabo-check
```

Note that you can run many of these shells in parallel.


### VS Code Remote Development

Install VS Code's **Dev Containers** extension, start the Compose project, and
then run **Dev Containers: Attach to Running Container...** from the Command
Palette. Select the `karabo` container and open `/home/karabouser/framework` as the
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
probe; terminals still source `/home/karabouser/framework/activate` via `.bashrc`.

## Podman on Windows 11

Extensive instruction can be found at

https://github.com/podman-container-tools/podman/blob/main/docs/tutorials/podman-for-windows.md

In short:

Install the `Windows Terminal` via the Windows store or by running

```sh
winget install Microsoft.WindowsTerminal
```

in the Windos CMD or PowerShell prompt.
We recommend to run the commands in the PowerShell.

Download podman installer v6.1.1  from

https://github.com/podman-container-tools/podman/releases

e.g. `podman-installer-windows-amd64.msi`

(or `...arm64.ms`), matching your machine architecture, and execute it,
e.g. by double-click.

When prompted, choose WSLv2.

It is also recommended to install the `Podman Desktop` from

https://podman-desktop.io/docs/installation/windows-install

It gives you nice overview and configuration options in case of
troubleshooting.

Download `podman-karabo-run-main.zip` from
https://git.xfel.eu/Karabo/podman-karabo
(via Code -> Download source code -> Zip) and unpack to where it suits
(right-click `Extract-All`).

In a new PowerShell, `cd` into that directory (where the `compose.yaml`
file is located) and execute

```sh
podman machine init
podman machine start
podman compose up --build
```
(If the latter command fails with timeout in some download step, simply retry.)

Keep that shell up and running. With `Ctrl-C` you could stop it, but that
exits also the shells you opened (see below).

Continue now with the generic section about `Developing in the Container`.

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

### Resetting a Locked Karabo Service Volume

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
