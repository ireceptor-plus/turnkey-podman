#!/bin/sh

SCRIPT_DIR=`dirname "$0"`
APACHE_LOG_FOLDER="${SCRIPT_DIR}/../.apache_log"
AWSTATS_FOLDER="${SCRIPT_DIR}/../.awstats"

mkdir -p "${APACHE_LOG_FOLDER}"
mkdir -p "${AWSTATS_FOLDER}"

# retrieve absolute paths (required by Docker)
APACHE_LOG_FOLDER=$(cd $APACHE_LOG_FOLDER; pwd)
AWSTATS_FOLDER=$(cd $AWSTATS_FOLDER; pwd)

SCRIPT_DIR_FULL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
POD_CONF_FILE="podman.conf.sh"
. $SCRIPT_DIR_FULL/$POD_CONF_FILE

echo "Delete any existing AWStats container..."
#sudo docker stop awstats > /dev/null 2>&1 && sudo docker rm awstats > /dev/null 2>&1
podman stop awstats> /dev/null 2>&1 && podman rm awstats > /dev/null 2>&1
echo "Done"
echo

echo "Dumping iReceptor Turnkey API container log into ${APACHE_LOG_FOLDER} ..."
#sudo docker-compose --file ${SCRIPT_DIR}/docker-compose.yml --project-name turnkey-service logs ireceptor-api | cut -f2 -d'|' > "${APACHE_LOG_FOLDER}/access.log"
podman logs ireceptor-api | cut -f2 -d'|' > "${APACHE_LOG_FOLDER}/access.log"

echo "Done"
echo

echo "Starting AWStats container..."
#sudo docker run \
#    --detach \
#    --restart always \
#    --publish 8088:80 \
#    --name awstats \
#    --env AWSTATS_CONF_LOGFORMAT=' %host %other %logname %time1 %methodurl %code %bytesd %refererquot %uaquot' \
#    --volume "${APACHE_LOG_FOLDER}":/var/local/log:ro \
#    --volume "${AWSTATS_FOLDER}":/var/lib/awstats \
#    ireceptor/service-awstats:latest > /dev/null
#echo "Done"
#echo
podman run \
    --detach \
    --restart always \
    --publish 8088:80 \
    --name awstats \
    --env AWSTATS_CONF_LOGFORMAT=' %host %other %logname %time1 %methodurl %code %bytesd %refererquot %uaquot' \
    --volume "${APACHE_LOG_FOLDER}":/var/local/log:ro,Z \
    --volume "${AWSTATS_FOLDER}":/var/lib/awstats:Z \
    ireceptor/service-awstats:latest > /dev/null

#--pod=${POD_NAME_SVC}\

echo "Running AWStats..."
#sudo docker exec awstats awstats_updateall.pl now
podman exec awstats awstats_updateall.pl now
echo "Done"
echo

# confirm success
echo "Your web statistics are now available at http://localhost:8088"
echo 'Note: you may need to replace "localhost" by this machine hostname'
