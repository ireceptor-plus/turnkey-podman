#!/bin/bash

SCRIPT_DIR=`dirname "$0"`
#SCRIPT_DIR_FULL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPT_DIR_FULL="$( readlink -f ${SCRIPT_DIR}  )";
POD_CONF_FILE="podman.conf.sh" 
#echo $SCRIPT_DIR
#echo $SCRIPT_DIR_FULL
#readlink -f  ${SCRIPT_DIR}
#exit

if [ ! -f "$SCRIPT_DIR/$POD_CONF_FILE" ]; then
    echo "The file $POD_CONF_FILE does not exist. Edit file podman.conf.sh.EDIT then remove .EDIT"
	exit
fi


# read configuration for turnkey pod
. $SCRIPT_DIR_FULL/$POD_CONF_FILE 

#echo --- BIN_PODMAN  ---  $PODMAN_CMD
log "[$POD_NAME_SVC installation]"
log "pod service name: $POD_NAME_SVC"
log "pod external port: $POD_EX_PORT"
log "user id running mongo db container: $POD_USER_ID"

# -----------------------------------------------------------------------------
# required commands
commands=("podman" "curl" "readlink" "openssl");
for i in "${commands[@]}"
do
	if ! [ $(command -v $i) > 0 ];then
		log "	$i command could not be found, install first. "
		exit
	else
		log "	$i command available"		
	fi
done
# -----------------------------------------------------------------------------
# install Docker

# install Docker Compose

# -----------------------------------------------------------------------------
# MongoDB optimization
# https://docs.mongodb.com/manual/tutorial/transparent-huge-pages/
log "Installing system service to disable Transparent Huge Pages (recommended by MongoDB).."

sudo cp ${SCRIPT_DIR}/disable-transparent-huge-pages.service /etc/systemd/system/disable-transparent-huge-pages.service 
sudo systemctl daemon-reload
sudo systemctl start disable-transparent-huge-pages
sudo systemctl enable disable-transparent-huge-pages
if cat /sys/kernel/mm/transparent_hugepage/enabled | grep -q 'never'; then
		log "	ok"
else
		log"	failed, check service disable-transparent-huge-pages.service"
		exit
fi


# -----------------------------------------------------------------------------
# db folder
log "create .mongodb_data folder"
if [ ! -e .mongodb_data  ];then
	# mongodb data folder
	mkdir .mongodb_data >> $SCRIPT_DIR/$LOGFILE_NAME 
	podman unshare chown $POD_USER_ID:$POD_USER_ID -R .mongodb_data
	
	# parent bkup dir for this pod
	mkdir -p ${PATH_BKUP_DIR}/$POD_NAME_SVC >> $SCRIPT_DIR/$LOGFILE_NAME
	#podman unshare chown $POD_USER_ID:$POD_USER_ID -R ${PATH_BKUP_DIR}/$POD_NAME_SVC
	
	# backups created here
	mkdir -p ${PATH_BKUP_DIR}/$POD_NAME_SVC/incoming
	#podman unshare chown $POD_USER_ID:$POD_USER_ID -R ${PATH_BKUP_DIR}/$POD_NAME_SVC/incoming

	mkdir -p ${PATH_BKUP_DIR}/$POD_NAME_SVC/backup.daily
	#podman unshare chown $POD_USER_ID:$POD_USER_ID -R ${PATH_BKUP_DIR}/$POD_NAME_SVC/backup.daily

	mkdir -p ${PATH_BKUP_DIR}/$POD_NAME_SVC/backup.weekly
    #podman unshare chown $POD_USER_ID:$POD_USER_ID -R ${PATH_BKUP_DIR}/$POD_NAME_SVC/backup.weekly

	mkdir -p ${PATH_BKUP_DIR}/$POD_NAME_SVC/backup.monthly
    #podman unshare chown $POD_USER_ID:$POD_USER_ID -R ${PATH_BKUP_DIR}/$POD_NAME_SVC/backup.monthly

	mkdir -p ${PATH_BKUP_DIR}/$POD_NAME_SVC/restore
    #podman unshare chown $POD_USER_ID:$POD_USER_ID -R ${PATH_BKUP_DIR}/$POD_NAME_SVC/restore

	# copy readme to parent bkup dir
	cp ${SCRIPT_DIR}/README_BKUP.md ${PATH_BKUP_DIR}/$POD_NAME_SVC/
else
	log "	data directory for mongo db already exists"
	exit
fi

# -----------------------------------------------------------------------------
# generate and install self-signed SSL certificate for HTTPS
SSL_FOLDER="${SCRIPT_DIR}/../.ssl"

HTTPS_ENABLED="FALSE"
HTTPS_SELF="FALSE"
HTTPS_CUSTOM="FALSE"

if [ "$CERT_HTTPS_ENABLED_SELFSIGNED" = "TRUE" ] && [ "$CERT_HTTPS_ENABLED_CUSTOM" = "TRUE" ]; then
   log "specify https service with custom or self signed certificate, exiting."
	exit
fi
if [ "$CERT_HTTPS_ENABLED_SELFSIGNED" = "TRUE" ]; then
   	log "enable https with self signed certificates.."
	HTTPS_ENABLED="TRUE"
	HTTPS_SELF="TRUE"
fi
if [ "$CERT_HTTPS_ENABLED_CUSTOM" = "TRUE" ]; then
   log "enable https with custom certificates.."
	HTTPS_ENABLED="TRUE"
	HTTPS_CUSTOM="TRUE"
fi

echo on  $HTTPS_ENABLED
echo self  $HTTPS_SELF
echo custom $HTTPS_CUSTOM

log "Installing SSL certificate.."
if [ ! -e .ssl ];then
    mkdir .ssl >> $SCRIPT_DIR/$LOGFILE_NAME 
    openssl rand -out ~/.rnd -hex 256 
    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
        -subj "/C=CA/ST=BC/L=Vancouver/O=iReceptor/CN=ireceptor-turnkey" \
        -keyout $SSL_FOLDER/private-key.pem  -out $SSL_FOLDER/certificate.pem
    cp $SSL_FOLDER/certificate.pem $SSL_FOLDER/intermediate.pem

	# overwrite with custom certificate files
	if [ "$HTTPS_ENABLED" = "TRUE"  ]  &&  [ "$HTTPS_CUSTOM" = "TRUE" ]; then
		rm $SSL_FOLDER/certificate.pem && cp $CERT_HTTPS_FULL_PATH_CERT $SSL_FOLDER/certificate.pem
		rm $SSL_FOLDER/private-key.pem && cp $CERT_HTTPS_FULL_PATH_CERTKEY $SSL_FOLDER/private-key.pem
		rm $SSL_FOLDER/intermediate.pem && cp $CERT_HTTPS_FULL_PATH_CERTCHAIN $SSL_FOLDER/intermediate.pem
	fi
	# copy custom apache conf to tmp folder, will be installed below
	if [ "$HTTPS_ENABLED" = "TRUE"  ]  &&  [ ! -z "$HTTPS_CUSTOM_CONF_FULL_PATH" ]; then
    	cp $HTTPS_CUSTOM_CONF_FULL_PATH $SSL_FOLDER/000-default.conf
	fi

    podman unshare chown $POD_USER_ID:$POD_USER_ID -R .ssl
	echo "Done"
    echo	
else
  log "   directory for ssl certificate already exists"
  exit
fi


# -----------------------------------------------------------------------------
#
log "check for existing pod.."
podman pod exists $POD_NAME_SVC 
if [ $? -eq 0  ]; then
	log "	pod with that name already exists."
	exit
fi

# pull images 
podman pull registry.hub.docker.com/ireceptor/repository-mongodb:$DATABASE_TAG
podman pull registry.hub.docker.com/ireceptor/service-php-mongodb:$API_TAG
podman pull registry.hub.docker.com/ireceptor/dataloading-mongo:$DATALOADING_TAG
#podman pull registry.hub.docker.com/ireceptor/dataloading-mongo:$PERFORMANCE_TESTING_TAG

log "creating the turnkey-service pod.."
podman pod create --name $POD_NAME_SVC --share net -p $POD_EX_PORT:80 -p $POD_EX_PORT_HTTPS:443 -p $POD_EX_PORT_DB:27017 
#--share net -p $POD_EX_PORT:80 -p 8088:88

log "add container ireceptor-database"
podman run --user $POD_USER_ID -d --pod=$POD_NAME_SVC \
            -e MONGO_INITDB_DATABASE="ireceptor" \
			-v .mongodb_data:/data/db:Z \
			-v ${PATH_BKUP_DIR}/$POD_NAME_SVC:/mnt/bkup:Z \
            --name=ireceptor-database${DATABASE_CONT_NAME_SUFFIX} \
			ireceptor/repository-mongodb:$DATABASE_TAG 

# HTTPS_CUSTOM_CONF_FULL_PATH
log "add container ireceptor-api"
podman run -d --pod=$POD_NAME_SVC \
            -e DB_HOST="localhost" \
			-e DB_DATABASE="ireceptor" \
			-e DB_SAMPLES_COLLECTION="sample" \
			-e DB_SEQUENCES_COLLECTION="sequence" \
			-v .ssl:/etc/apache2/ssl:Z \
			--name=ireceptor-api${API_CONT_NAME_SUFFIX} \
			ireceptor/service-php-mongodb:$API_TAG

#log "add container ireceptor-dataloading" 
mkdir -p tmp
#podman run -d --pod=$POD_NAME_SVC -e DB_HOST="localhost" -e DB_DATABASE="ireceptor" -v tmp:/scratch:Z --name=ireceptor-dataloading ireceptor/dataloading-mongo:turnkey-v3-dataloading
#Error: SELinux relabeling of /tmp is not allowed

wait "containers starting ..." 10

#exit
# -----------------------------------------------------------------------------
# launch on boot
# pod-turnkey-service.service
# container-ireceptor-api.service
# container-ireceptor-database.service
mkdir -p ~/.config/systemd/user/

#podman generate systemd --name $POD_NAME_SVC > ~/.config/systemd/user/pod-${POD_NAME_SVC}.service
#systemctl enable pod-${POD_NAME_SVC}.service --user
podman generate systemd --files --name $POD_NAME_SVC

# move file to user directory for systemd 
cp pod-${POD_NAME_SVC}.service  ~/.config/systemd/user/pod-${POD_NAME_SVC}.service
rm pod-${POD_NAME_SVC}.service

cp container-ireceptor-database${DATABASE_CONT_NAME_SUFFIX}.service \
          ~/.config/systemd/user/container-ireceptor-database${DATABASE_CONT_NAME_SUFFIX}.service
rm container-ireceptor-database${DATABASE_CONT_NAME_SUFFIX}.service

cp container-ireceptor-api${API_CONT_NAME_SUFFIX}.service \
          ~/.config/systemd/user/container-ireceptor-api${API_CONT_NAME_SUFFIX}.service
rm container-ireceptor-api${API_CONT_NAME_SUFFIX}.service

#cp container-ireceptor-dataloading.service ~/.config/systemd/user/container-ireceptor-dataloading.service
#rm container-ireceptor-dataloading.service

wait "systemctl enable pod..." 4
systemctl enable pod-${POD_NAME_SVC}.service --user

# https -----------------------------------------------------------------------
if [ "$HTTPS_ENABLED" = "FALSE" ]; then
	$SCRIPT_DIR/disable_https.sh
	wait "disabling https, consider protecting repository e.g. with a reverse proxy)" 4
fi

if [ "$HTTPS_ENABLED" = "TRUE"  ]  &&  [ ! -z "$HTTPS_CUSTOM_CONF_FULL_PATH" ]; then
	podman exec ireceptor-api${API_CONT_NAME_SUFFIX} \
		sh -c 'mv /etc/apache2/ssl/000-default.conf /etc/apache2/sites-available'
	wait "restart with https and custom configuratiopn file" 4
fi

# service start ---------------------------------------------------------------
podman pod stop $POD_NAME_SVC
sleep 2
log "starting systemd service ..."
systemctl --user start pod-${POD_NAME_SVC}.service
sleep 2
log "running processes in pod"
podman pod top $POD_NAME_SVC
#systemctl status pod-${POD_NAME_SVC}.service --user
sleep 2
echo "calling service .."

if [ "$HTTPS_ENABLED" = "TRUE" ]; then
	echo "curl https://${HTTPS_HOSTNAME}:$POD_EX_PORT_HTTPS/airr/v1/info"
	echo ""
	curl https://${HTTPS_HOSTNAME}:$POD_EX_PORT_HTTPS/airr/v1/info
else
	echo "curl http://localhost:$POD_EX_PORT/airr/v1/info"
	echo ""
	curl http://localhost:$POD_EX_PORT/airr/v1/info
fi

echo ""
#echo "curl http://localhost:$POD_EX_PORT/airr/v1/repertoire"
#echo ""
#curl http://localhost:$POD_EX_PORT/airr/v1/repertoire

echo "iReceptor Service Turnkey runs as a user service"
echo "check service : systemctl status pod-${POD_NAME_SVC}.service --user"
echo "start service : systemctl start pod-${POD_NAME_SVC}.service --user"
echo "stop service     : systemctl stop pod-${POD_NAME_SVC}.service --user"
echo "disable service : systemctl disable pod-${POD_NAME_SVC}.service --user"
echo "enable service : systemctl enable pod-${POD_NAME_SVC}.service --user"
echo 
# -----------------------------------------------------------------------------
# start turnkey
#${SCRIPT_DIR}/start_turnkey.sh

# The Mongo query plans are forgotten each time mongo is stopped.
# They need to be recreated at startup.
${SCRIPT_DIR}/create_database_queryplans.sh

# -----------------------------------------------------------------------------
# confirm successful installation
echo "Congratulations, your iReceptor Service Turnkey is up and running."
echo "For more information, go to https://github.com/sfu-ireceptor/turnkey-service-php"

