#!/bin/sh

SCRIPT_DIR=`dirname "$0"`

# stop Docker containers
echo "Stopping Docker containers.."
${SCRIPT_DIR}/stop_turnkey.sh
echo "Done"
echo

# update local git repository
echo "Updating source code.."
git -C ${SCRIPT_DIR} pull.rebase false
echo "Done"
echo

SCRIPT_DIR_FULL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
POD_CONF_FILE="podman.conf.sh"
. $SCRIPT_DIR_FULL/$POD_CONF_FILE

# download latest Docker images from Docker Hub
echo "Downloading Docker images from Docker Hub.."
#sudo docker-compose --file ${SCRIPT_DIR}/docker-compose.yml --project-name turnkey-service pull
podman pull ireceptor/repository-mongodb:$DATABASE_TAG
podman pull ireceptor/service-php-mongodb:$API_TAG
podman pull ireceptor/dataloading-mongo:$DATALOADING_TAG
podman pull ireceptor/dataloading-mongo:$PERFORMANCE_TESTING_TAG
echo "Done"
echo

# start Docker containers
echo "Starting Docker containers.."
${SCRIPT_DIR}/start_turnkey.sh
echo "Done"
echo

# delete stopped containers and dangling images
echo "Removing old Docker images and containers.."
#sudo docker system prune --force
podman system prune --force
echo "Done"
echo

# confirm successful installation
echo "Congratulations, your iReceptor Service Turnkey has been updated successfully."
echo "For more information, go to https://github.com/sfu-ireceptor/turnkey-service-php"

log "update_turnkey"

# trigger db backup
touch $DO_BKUP_FLAG
