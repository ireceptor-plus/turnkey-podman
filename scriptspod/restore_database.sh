#!/bin/sh
SCRIPT_DIR=`dirname "$0"`

restore_abs_file_path=$1
parent_dir="$(dirname "$restore_abs_file_path")"
base_name="$(basename "$restore_abs_file_path")"

SCRIPT_DIR_FULL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
POD_CONF_FILE="podman.conf.sh"
# read configuration for turnkey pod
. $SCRIPT_DIR_FULL/$POD_CONF_FILE

#sudo docker-compose --file ${SCRIPT_DIR}/docker-compose.yml --project-name turnkey-service exec -T ireceptor-database \
#	sh -c 'mongo --quiet /app/scripts/drop_indexes.js && \
#			echo && \
#			echo "Restoring database..." && \
#			mongorestore --noIndexRestore --archive && \
#			echo "Done" && \
#			echo && \
#			cd /app && mongo --quiet /app/scripts/create_indexes.js && \
#			cd /app && mongo --quiet /app/scripts/create_query_plans.js && \
#			echo && \
#			echo "Your database was sucessfully restored."'


# --log-level debug 
podman exec \
            -i \
            -e MONGO_INITDB_DATABASE="ireceptor" \
            -e BASE_NAME=$base_name \
            ireceptor-database${DATABASE_CONT_NAME_SUFFIX} \
			sh -c 'mongo --quiet /app/scripts/drop_indexes.js && \
			echo && \
			echo "Restoring database..." && \
			mongorestore --noIndexRestore --archive=/mnt/bkup/restore/$BASE_NAME --gzip && \
			echo "Done" && \
			echo && \
			cd /app && mongo --quiet /app/scripts/create_indexes.js && \
			cd /app && mongo --quiet /app/scripts/create_query_plans.js && \
			echo && \
			echo "Your database was sucessfully restored."'

log "restore database: ${restore_abs_file_path}"

