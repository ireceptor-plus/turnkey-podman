#!/bin/bash

SCRIPT_DIR=`dirname "$0"`
#SCRIPT_DIR_FULL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPT_DIR_FULL="$( readlink -f ${SCRIPT_DIR}  )";
POD_CONF_FILE="podman.conf.sh"
# read configuration for turnkey pod
. $SCRIPT_DIR_FULL/$POD_CONF_FILE

systemctl start pod-${POD_NAME_SVC}.service --user
#systemctl status pod-${POD_NAME_SVC}.service --user --no-pager
sleep 2
log "service start pod-${POD_NAME_SVC}.service started."
#echo "Starting iReceptor Service Turnkey.."
#sudo docker-compose --file ${SCRIPT_DIR}/docker-compose.yml --project-name turnkey-service up -d
#echo "Done"
#echo

# systemctl enable pod-${POD_NAME_SVC}.service --user
#echo "iReceptor Service Turnkey runs as a user service"
#echo "check service : systemctl status pod-${POD_NAME_SVC}.service --user"
#echo "start service : systemctl start pod-${POD_NAME_SVC}.service --user"
#echo "stop service 	: systemctl stop pod-${POD_NAME_SVC}.service --user"
#echo "disable service : systemctl disable pod-${POD_NAME_SVC}.service --user"
#echo "enable service : systemctl enable pod-${POD_NAME_SVC}.service --user"

# The Mongo query plans are forgotten each time mongo is stopped.
# They need to be recreated at startup.
${SCRIPT_DIR}/create_database_queryplans.sh
