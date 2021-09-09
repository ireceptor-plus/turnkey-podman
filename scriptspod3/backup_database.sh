#!/bin/bash

restore_abs_file_path=$1
parent_dir="$(dirname "$restore_abs_file_path")"
base_name="$(basename "$restore_abs_file_path")"


SCRIPT_DIR=`dirname "$0"`
#SCRIPT_DIR_FULL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPT_DIR_FULL="$( readlink -f ${SCRIPT_DIR}  )";
POD_CONF_FILE="podman.conf.sh"
# read configuration for turnkey pod
. $SCRIPT_DIR_FULL/$POD_CONF_FILE
#echo ${DO_BKUP_FLAG}
if [ -f "${DO_BKUP_FLAG}" ]; then
    log "DO_BKUP_FLAG exists...";
	rm ${DO_BKUP_FLAG}
else 
	exit;
fi

#bkup_file_name=mongodb_${host_name}_${POD_NAME_SVC}_$(date +%s).dump
bkup_file_name=mongodb_${host_name}_${POD_NAME_SVC}_$(date +%Y%m%dT%H%M%S).gzip.dump

#sudo docker-compose --file ${SCRIPT_DIR}/docker-compose.yml --project-name turnkey-service exec -T ireceptor-database \
#	sh -c 'mongodump --archive'

podman exec -u root \
            -e MONGO_INITDB_DATABASE="ireceptor" \
            -e bkup_file_name=$bkup_file_name \
            ireceptor-database$DATABASE_CONT_NAME_SUFFIX \
		    sh -c 'mongodump --archive=/mnt/bkup/incoming/$bkup_file_name --gzip' 

log "backup db: ${bkup_file_name}"

