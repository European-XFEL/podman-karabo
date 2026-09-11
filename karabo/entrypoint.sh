#!/usr/bin/env bash
set -euo pipefail

installation=/home/karabouser/framework


if [ ! -f "first_run" ]; then
    karabo-activate --init-to "$installation" --backbone \
        --broker-host amqp://xfel:karabo@rabbitmq:5672 --broker-topic karabo \
        --influx-db tcp://influxdb:8086

    data_logger_run="$installation/var/service/karabo_dataLoggerManager/run"
    chmod +w "$data_logger_run"
    sed -i 's/"logger": "InfluxDataLogger", //g' "$data_logger_run"

    # InfluxLogReader in Karabo 3.1 reads these newer variable names, whereas
    # karabo-activate currently creates the older KARABO_INFLUX_* names above.
    printf '%s' 'tcp://influxdb:8086' > "$installation/var/environment/KARABO_INFLUXDB_QUERY_URL"
    printf '%s' 'karabo' > "$installation/var/environment/KARABO_INFLUXDB_DBNAME"

    # The packaged GUI service defaults to the obsolete KaraboDataLoggerManager
    # device ID. Point it at the manager created by this standalone installation.
    sed -i 's/"port": 44444}}/"port": 44444, "dataLogManagerId": "Karabo_DataLoggerManager_0"}}/' \
        "$installation/var/service/karabo_guiServer/run"
fi

# The activation script prepares the environment for the command below.
source "$installation/activate"

# Create empty file as indicator that this script already ran once
touch first_run

karabo-start
exec "$@"
