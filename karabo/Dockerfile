FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --yes --no-install-recommends curl git procps \
    python3-venv vim nano emacs-nox \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a dedicated 'karabo' user with a pinned UID/GID.
# 1001 leaves 1000 free to match the host user in bind mounts.
RUN groupadd -g 1001 karabogroup && \
    useradd --no-log-init -u 1001 -g karabogroup -m -s /usr/sbin/nologin karabouser

WORKDIR /home/karabouser

COPY entrypoint.sh /home/karabouser/bin/karabo-entrypoint
RUN chmod +x /home/karabouser/bin/karabo-entrypoint


# Run the container as the unprivileged user (numeric UID: survives /etc/passwd changes)
USER 1001:1001

ENV PATH=/home/karabouser/karabo-venv/bin:$PATH

RUN printf '%s\n' '[ -f /home/karabouser/framework/activate ] && source /home/karabouser/framework/activate' \
    >> /home/karabouser/.bashrc


RUN python3 -m venv /home/karabouser/karabo-venv \
    && /home/karabouser/karabo-venv/bin/pip install 'karabo[full]'

ENTRYPOINT ["/home/karabouser/bin/karabo-entrypoint"]
CMD ["sleep", "infinity"]
