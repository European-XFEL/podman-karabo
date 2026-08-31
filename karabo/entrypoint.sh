#!/usr/bin/env bash
set -euo pipefail

installation=/opt/karabo/framework

if [ ! -f "$installation/activate" ]; then
    karabo-activate --init-to "$installation" --backbone \
        --broker-host amqp://xfel:karabo@rabbitmq:5672 --broker-topic karabo \
        --influx-db tcp://influxdb:8086

    data_logger_run="$installation/var/service/karabo_dataLoggerManager/run"
    chmod +w "$data_logger_run"
    sed -i 's/"logger": "InfluxDataLogger", //g' "$data_logger_run"
fi

# The activation script prepares the environment for the command below.
source "$installation/activate"
karabo-start
exec "$@"
