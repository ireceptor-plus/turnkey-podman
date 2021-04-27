#!/bin/sh

# check number of arguments
NB_ARGS=2
if [ $# -ne $NB_ARGS ];
then
    echo "$0: wrong number of arguments ($# instead of $NB_ARGS)"
    echo "usage: $0 (ireceptor|repertoire) <metadata_file.csv>"
    exit 1
fi

REPERTOIRE_TYPE="$1"
shift

FILE_ABSOLUTE_PATH=`realpath "$1"`
FILE_FOLDER=`dirname "$FILE_ABSOLUTE_PATH"`
FILE_NAME=`basename "$FILE_ABSOLUTE_PATH"`

SCRIPT_DIR=`dirname "$0"`
SCRIPT_DIR_FULL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
POD_CONF_FILE="podman.conf.sh"
. $SCRIPT_DIR_FULL/$POD_CONF_FILE

# create log file
LOG_FOLDER=${SCRIPT_DIR}/../log
mkdir -p $LOG_FOLDER
TIME1=`date +%Y-%m-%d_%H-%M-%S`
LOG_FILE=${LOG_FOLDER}/${TIME1}_${FILE_NAME}.log

# make available to docker-compose.yml
export FILE_FOLDER

# Notes:
# sudo -E: make environment variables available to the command run as root
# docker-compose --rm: delete container afterwards 
# docker-compose -e: these variables will be available inside the container
# (but not accessible in docker-compose.yml)
# "ireceptor-dataloading" is the service name defined in docker-compose.yml 
# sh -c '...' is the command executed inside the container
# $DB_HOST and $DB_DATABASE are defined in docker-compose.yml and will be
# substituted only when the python command is executed, INSIDE the container
#sudo -E docker-compose --file ${SCRIPT_DIR}/docker-compose.yml --project-name turnkey-service run --rm \
#			-e FILE_NAME="$FILE_NAME" \
#			-e FILE_FOLDER="$FILE_FOLDER" \
#			-e REPERTOIRE_TYPE="$REPERTOIRE_TYPE" \
#			ireceptor-dataloading  \
#				sh -c 'python /app/dataload/dataloader.py -v \
#					--mapfile=/app/config/AIRR-iReceptorMapping.txt \
#					--host=$DB_HOST \
#					--database=$DB_DATABASE \
#					--repertoire_collection sample \
#					--$REPERTOIRE_TYPE \
#					-f /scratch/$FILE_NAME' \
# 	2>&1 | tee $LOG_FILE

#echo FILE_NAME  $FILE_NAME
#echo FILE_FOLDER  $FILE_FOLDER
#echo REPERTOIRE_TYPE $REPERTOIRE_TYPE
#echo POD_NAME_SVC ${POD_NAME_SVC} 

podman run --rm -it --pod=${POD_NAME_SVC}   \
     -e DB_HOST="localhost" \
     -e DB_DATABASE="ireceptor" \
	 -e FILE_NAME="$FILE_NAME" \
	 -e FILE_FOLDER="$FILE_FOLDER" \
	 -e REPERTOIRE_TYPE="${REPERTOIRE_TYPE}" \
     -v $FILE_FOLDER:/scratch:Z \
	 --name=ireceptor-dataloading${DATALOADING_CONT_NAME_SUFFIX} \
	 ireceptor/dataloading-mongo:$DATALOADING_TAG \
     sh -c 'python /app/dataload/dataloader.py \
	 -v --mapfile=/app/config/AIRR-iReceptorMapping.txt \
	 --host=$DB_HOST \
	 --database=$DB_DATABASE \
	 --repertoire_collection sample \
	 --$REPERTOIRE_TYPE \
	 -f /scratch/$FILE_NAME' 2>&1 | tee $LOG_FILE

#curl --data "{}" "http://localhost:$POD_EX_PORT/airr/v1/repertoire"
log "load metadata: ${FILE_NAME}, check ${LOG_FILE}"

# trigger db backup
touch $DO_BKUP_FLAG
