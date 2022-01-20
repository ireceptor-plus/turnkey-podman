#!/bin/sh

SCRIPT_DIR=`dirname "$0"`
SCRIPT_DIR_FULL="$( readlink -f ${SCRIPT_DIR}  )";
POD_CONF_FILE="podman.conf.sh"
# read configuration for turnkey pod
. $SCRIPT_DIR_FULL/$POD_CONF_FILE

log "Enabling HTTPS.."
#sudo docker-compose --file ${SCRIPT_DIR}/docker-compose.yml --project-name turnkey-service exec -T ireceptor-api \
#		sh -c 'a2dissite -q http.conf && a2ensite -q 000-default.conf && service apache2 reload'

podman exec \
            ireceptor-api${API_CONT_NAME_SUFFIX} sh \
            -c 'a2dissite -q http.conf && a2ensite -q 000-default.conf && service apache2 reload'

log "Done"
echo


