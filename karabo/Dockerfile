FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --yes --no-install-recommends git python3-venv \
    && python3 -m venv /opt/karabo-venv \
    && /opt/karabo-venv/bin/pip install 'karabo[full]' \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PATH=/opt/karabo-venv/bin:$PATH

RUN printf '%s\n' '[ -f /opt/karabo/framework/activate ] && source /opt/karabo/framework/activate' \
    >> /root/.bashrc

COPY entrypoint.sh /usr/local/bin/karabo-entrypoint
RUN chmod +x /usr/local/bin/karabo-entrypoint

ENTRYPOINT ["/usr/local/bin/karabo-entrypoint"]
CMD ["sleep", "infinity"]
