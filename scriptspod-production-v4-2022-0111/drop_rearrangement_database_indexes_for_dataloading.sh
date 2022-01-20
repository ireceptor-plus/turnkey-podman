#!/bin/bash


SCRIPT_DIR=`dirname "$0"`
SCRIPT_DIR_FULL="$( readlink -f ${SCRIPT_DIR}  )";
POD_CONF_FILE="podman.conf.sh"
# read configuration for turnkey pod
. $SCRIPT_DIR_FULL/$POD_CONF_FILE

#sudo docker-compose --file ${SCRIPT_DIR}/docker-compose.yml --project-name turnkey-service exec -T ireceptor-database \
#		sh -c 'cd /app && mongo --quiet $MONGO_INITDB_DATABASE /app/scripts/drop_indexes_dataloading.js'

podman exec -e MONGO_INITDB_DATABASE="ireceptor" \
			ireceptor-database${DATABASE_CONT_NAME_SUFFIX}  \
			sh -c 'cd /app && mongo --quiet $MONGO_INITDB_DATABASE /app/scripts/drop_indexes_dataloading.js'


