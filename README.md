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

## 1a. Podman on Windows 11

Extensive instruction can be found at

https://github.com/podman-container-tools/podman/blob/main/docs/tutorials/podman-for-windows.md

In short:

1. Install the `Windows Terminal` via the Windows store or by running

   ```sh
   winget install Microsoft.WindowsTerminal
   ```

   in the Windos CMD or PowerShell prompt.
   We recommend to run the commands in the PowerShell.

2. Download podman installer v6.1.1  from

   https://github.com/podman-container-tools/podman/releases

   e.g. `podman-installer-windows-amd64.msi`

   (or `...arm64.ms`), matching your machine architecture, and execute it,
   e.g. by double-click.

   When prompted, choose WSLv2.

3. It is also recommended to install the `Podman Desktop` from

   https://podman-desktop.io/docs/installation/windows-install

   It gives you nice overview and configuration options in case of
   troubleshooting.

4. Download `podman-karabo-run-main.zip` from
   https://github.com/European-XFEL/podman-karabo 
   (by clicking on the 'Code' button then selecting 'Download ZIP') 
   and unpack to where it suits (right-click `Extract-All`).

5. In a new PowerShell, `cd` into that directory (where the `compose.yaml`
   file is located) and execute

   ```sh
   podman machine init
   podman machine start
   ```

Continue with Step 2, `Karabo Workshop Environment Setup`.

## 1b. Podman on Apple Silicon

1. Install Podman and its compose provider using Homebrew:

   ```sh
   brew install podman
   brew install podman-compose
   ```

2. Podman on macOS uses a Linux virtual machine. On Apple Silicon, create an
   Apple Hypervisor-backed machine with Rosetta support (enabled by default) so it
   can emulate x86_64 Linux binaries. Allocate memory during creation for Karabo
   and the x86_64-emulated VS Code Server: use at least 4 GiB, preferably 8 GiB.
   The command below allocates 8 GiB (8192 MiB) before starting the machine.
   Use 4096 (4 GiB) if your Mac has limited RAM.:

   ```sh
   podman machine init --provider applehv --memory 8192 --now
   podman run --rm --platform linux/amd64 alpine uname -m
   ```

   The verification command should print `x86_64`.

If you already have a Podman machine that was not created with the Apple
Hypervisor provider, create a new `applehv` machine (or recreate the existing
one) before running the project. The `linux/amd64` platform in `compose.yaml`
selects the x86_64 image; emulation is slower than running a native image.

Continue with Step 2, `Karabo Workshop Environment Setup`.

## 2. Karabo Workshop Environment Setup

1. Checkout this repository and, within its root directory, follow these steps:

2. Start everything with:

   ```sh
   podman compose up --build
   ```

   If you use `docker` instead of `podman`, run instead:

   ```sh
   docker-compose build
   docker-compose up
   ```

   If startup fails with a timeout during a download, retry the command.

   Keep that shell up and running. With `Ctrl-C` you could stop it, but that
   exits also the shells you opened (see below).

The `karabo` service is intentionally pinned to `linux/amd64`, including on
Apple Silicon. Its first start persists a Karabo installation in the
`karabo-installation` volume.

On each start, its entrypoint sources `/home/karabouser/framework/activate`, runs
`karabo-start`, and then starts its configured command. The broker is therefore
available at `rabbitmq:5672` inside the container, using the `xfel` / `karabo`
credentials; InfluxDB is at `influxdb:8086`.
The Karabo GUI server is published on host port `44444`.

## 3. Host GUI

1. The Karabo GUI needs to be installed on the host separately from the container. For
   this workshop (and for Windows in general), we recommend downloading and installing
   a complete Karabo GUI bundle that matches your operating system from

   https://syncandshare.xfel.eu/index.php/s/tcdSdqLGKbqYoWb

2. In Linux (and possibly MacOS), you'll have to give the file writing permissions:

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

## 4. Developing in the Container

1. Keep the services running, then, in another shell of your host machine,
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

2. The Karabo environment is activated in this `bash` shell.
   You can check that and see which Karabo servers are available via

   ```sh
   karabo-check
   ```

   The result should look similar to

   ```shell-session
   karabouser@a6e251499597:~$ karabo-check
   boundserver_workshop_sim: up (pid 625) 15 seconds, normally down, running
   cppserver_workshop_sim: up (pid 626) 15 seconds, normally down, running
   karabo_configServer: up (pid 628) 15 seconds, normally down, running
   karabo_daemonServer: up (pid 624) 15 seconds, normally down, running
   karabo_dataLogger: up (pid 634) 15 seconds, normally down, running
   karabo_dataLoggerManager: up (pid 633) 15 seconds, normally down, running
   karabo_guiServer: up (pid 629) 15 seconds, normally down, running
   karabo_macroServer: up (pid 636) 15 seconds, normally down, running
   karabo_projectDBServer: up (pid 637) 15 seconds, normally down, running
   karabo_webAggregator: up (pid 627) 15 seconds, normally down, running
   karabo_webServer: up (pid 635) 15 seconds, normally down, running
   mdlserver_workshop_device: up (pid 632) 15 seconds, normally down, running
   mdlserver_workshop_gui: up (pid 631) 15 seconds, normally down, running
   mdlserver_workshop_pipe: up (pid 638) 15 seconds, normally down, running
   mdlserver_workshop_sim: up (pid 630) 15 seconds, normally down, running
   ```

   Note that you can run many of these shells in parallel.


### 4.1. VS Code Remote Development

If you prefer VS Code over `emacs`, `nano` and `vim` during the workshop, you could
connect VS Code running on your host system to the Karabo container.

1. Install VS Code's **Dev Containers** extension, start the Compose project, and
   then run **Dev Containers: Attach to Running Container...** from the Command
   Palette. Select the `karabo` container and open `/home/karabouser/framework` as the
   workspace. VS Code installs its server in the container and its integrated
   terminal uses the activated shell described above.

2. To use Podman with the Dev Containers extension, open VS Code **Settings**
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

