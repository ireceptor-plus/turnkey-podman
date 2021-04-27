#!/bin/sh

SCRIPT_DIR=`dirname "$0"`
SCRIPT_DIR_FULL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
POD_CONF_FILE="podman.conf.sh"
# read configuration for turnkey pod
. $SCRIPT_DIR_FULL/$POD_CONF_FILE

# create query plans
#sudo docker-compose --file ${SCRIPT_DIR}/docker-compose.yml --project-name turnkey-service exec -T ireceptor-database \
#		sh -c 'cd /app && mongo --quiet $MONGO_INITDB_DATABASE /app/scripts/create_query_plans.js'


podman exec -e MONGO_INITDB_DATABASE="ireceptor" ireceptor-database${DATABASE_CONT_NAME_SUFFIX} sh \
            -c 'cd /app && mongo --quiet $MONGO_INITDB_DATABASE /app/scripts/create_query_plans.js'
