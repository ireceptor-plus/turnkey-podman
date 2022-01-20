#!/bin/bash

SCRIPT_DIR=`dirname "$0"`
#SCRIPT_DIR_FULL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPT_DIR_FULL="$( readlink -f ${SCRIPT_DIR}  )";
POD_CONF_FILE="podman.conf.sh"
. $SCRIPT_DIR_FULL/$POD_CONF_FILE

#sudo docker-compose --file ${SCRIPT_DIR}/docker-compose.yml --project-name turnkey-service stop
systemctl --user stop pod-${POD_NAME_SVC}.service 
#systemctl --user --no-pager  status pod-${POD_NAME_SVC}.service 
sleep 2
log "service pod-${POD_NAME_SVC}.service stopped."

echo
#echo "Stopping AWStats..."
#sudo docker stop awstats > /dev/null 2>&1 && sudo docker rm awstats > /dev/null 2>&1
#echo "Done"
echo
