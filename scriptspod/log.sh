#!/bin/bash

SCRIPT_DIR=`dirname "$0"`
#SCRIPT_DIR_FULL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPT_DIR_FULL="$( readlink -f ${SCRIPT_DIR}  )";
POD_CONF_FILE="podman.conf.sh"
. $SCRIPT_DIR_FULL/$POD_CONF_FILE

echo "last 12 lines of containers in pod:" 
echo "-------------------------------------------------------------------------"
podman logs -n --tail 12 ireceptor-database
echo "-------------------------------------------------------------------------"
podman logs -n --tail 12  ireceptor-api 
#sudo docker-compose --file ${SCRIPT_DIR}/docker-compose.yml --project-name turnkey-service logs
