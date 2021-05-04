#!/bin/bash
SCRIPT_DIR=`dirname "$0"`
#SCRIPT_DIR_FULL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPT_DIR_FULL="$( readlink -f ${SCRIPT_DIR}  )";
POD_CONF_FILE="podman.conf.sh"
. $SCRIPT_DIR_FULL/$POD_CONF_FILE


# stop and disable turnkey service
systemctl --user stop pod-${POD_NAME_SVC}.service
systemctl --user disable pod-${POD_NAME_SVC}.service
# stop and remove turnkey-service pod
podman pod stop $POD_NAME_SVC
podman pod rm $POD_NAME_SVC
# stop and remove awstats container
#podman stop awstats
#podman rm awstats
# remove database folder
sudo rm -r .mongodb_data
# check where this file is coming from
rm 0
# remove log
rm ./scriptspod/$LOGFILE_NAME
# neede for adc-api-test dataset loading
rm -rf ${PATH_BKUP_DIR}/${POD_NAME_SVC}/restore
rm -rf ${PATH_BKUP_DIR}/${POD_NAME_SVC}/incoming
#export MONGO_DBDIR=/var/data/turnkey-service-php/.mongodb_data
