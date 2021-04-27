#!/bin/sh

SCRIPT_DIR=`dirname "$0"`
SCRIPT_DIR_FULL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
POD_CONF_FILE="podman.conf.sh"
# read configuration for turnkey pod
. $SCRIPT_DIR_FULL/$POD_CONF_FILE

echo -n "Starting $0: "
date

# create indexes
#sudo docker-compose --file ${SCRIPT_DIR}/docker-compose.yml --project-name turnkey-service exec -T ireceptor-database \
#		sh -c 'cd /app && mongo --quiet $MONGO_INITDB_DATABASE /app/scripts/create_indexes.js'

podman exec -e MONGO_INITDB_DATABASE="ireceptor" \
            ireceptor-database${DATABASE_CONT_NAME_SUFFIX} sh \
			-c 'cd /app && mongo --quiet $MONGO_INITDB_DATABASE /app/scripts/create_indexes.js'


# create query plans
${SCRIPT_DIR}/create_database_queryplans.sh

echo -n "Done $0: "
date
