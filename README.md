# iReceptor Turnkey scripts for podman

The provided scripts in scriptspod let the turnkey service (https://github.com/sfu-ireceptor/turnkey-service-php) run with podman instead of docker on operating systems where docker is not available like Centos 8.

The web\_stats scripts and test\_performance.sh have not yet been adjusted.

The scripts have been tested on the following operating systems:

* Centos 8.3
* Fedora 33,34
* Debian 11 RC1 Bullseye
* Alma Linux 8.5

## Installation of the scripts 

* scriptspod3 contains scripts for turnkey version 3
* scriptspod4 is for version 4
* scriptspod-production-v4-2022-0111 supports production-v4 (still in development) branch from 22-01-20 

Clone branch e.g. production-v4 from https://github.com/sfu-ireceptor/turnkey-service-php to a location where you have enough storage to host the amount of data you want to support. 

Copy scriptspod4 directory to turnkey-service installation directory and create a link $ ln -s scriptspod4 scriptspod  

## Edit file podman.conf.sh.EDIT

New configuration options are added with updated versions.

Configure the following variables then remove .EDIT from the file. 

Absolute path to your backup directory, the mongo db container will have this path inside its filesystem at /mnt/bkup
```
PATH_BKUP_DIR="/var/data/bkup"
```

You can run several installations of turnkey on same machine. In that case add a suffix to container names, e. g. dev, when running the latest container versions.
```
DATABASE_CONT_NAME_SUFFIX=""
API_CONT_NAME_SUFFIX=""
DATALOADING_CONT_NAME_SUFFIX=""
PERFORMANCE_TESTING_CONT_NAME_SUFFIX=""
```

Container tags are configured for production installation, for dev installations use second value.
```
# prod:turnkey-v3 dev:master
DATABASE_TAG="turnkey-v3"
# prod:turnkey-v3 dev:latest
API_TAG="turnkey-v3"
# prod:turnkey-v3-dataloading dev:turnkey-dataloading-latest
DATALOADING_TAG="turnkey-v3-dataloading"
# prod:turnkey-v3-performance dev:turnkey-performance-latest
PERFORMANCE_TESTING_TAG="turnkey-v3-performance"
```

Port on the host where the API endpoint is accessible. Open this port on the host firewall if required.
```
POD_EX_PORT="8443"
```

Port of the mongo database container on the host. Normally this port should not be accessible from outside the host.

```
POD_EX_PORT_DB="27017"
```

Name for pod, e.g. use turnkey-service and turnkey-service-dev for latest versions of containers.
```
POD_NAME_SVC="turnkey-service"
```

User id for running the database container.
```
POD_USER_ID="1000"
```

## Install turnkey service 

Change to turnkey installation folder, then run
```
scriptspod/install_turnkey.sh
```

## Start/Stop the turnkey service 

The install script will create a service pod-*POD\_NAME\_SVC*.service where *POD\_NAME\_SVC* is the name of the pod service.

```
systemctl start pod-POD_NAME_SVC.service --user 
systemctl stop pod-POD_NAME_SVC.service --user
```

## Load data to turnkey

Follow the documentation on the turnkey service repository, just call the same scripts in the scriptspod folder. 

The load_stats.sh will not work with this podman configuration (all containers in one pod), because the docker service database name is used but only the name localhost will work. 

To run the statistics creation script, start the dataloading container and change in /app/stats file stats_file_create.php (line 208) and file stats_file_laod.php (line 12) so that localhost is used instead of ireceptor-database in the MongoDB constructor.
 
Then run the script load_stats_mongo.sh from inside the container.


## Backup database

This is different from the turnkey with docker installation. Normally schedule backups from a cron job in case data has been loaded to the turnkey service. To run an unscheduled backup, create a file BKUP\_DB.FLAG in the backup directory for this turnkey instance, then run  

```
scriptspod/backup_database.sh
```

This will create a file in the incoming folder in PATH\_BKUP\_DIR/POD\_NAME\_SVC
mongodb\_SRVCENTOS01\_turnkey-service\_20210416T020201.gzip.dump

e.g. SRVCENTOS01 is your hostname, turnkey-service is the value of POD\_NAME\_SVC

## Restore a database

To restore a database move the database dump to the restore folder in PATH\_BKUP\_DIR/POD\_NAME\_SVC

e.g. move file mongodb\_SRVCENTOS01\_turnkey-service\_20210415T135049.gzip.dump from /var/data/bkup/turnkey-service/backup.daily/2021-04-15 to /var/data/bkup/turnkey-service/restore.

Then cd to turnkey installation folder and run scriptspod/restore\_database.sh mongodb\_SRVCENTOS01\_turnkey-service\_20210415T135049.gzip.dump. Do not specifiy a path, just give the filname.

The container will see the file in its own location and restore the database.

## cronjob for databse backups

Schedule the backup process when the data has changed. The data load scripts will trigger a database backup, this can be detected with a cron job.

```
# daily bkup for turnkey-service-php
2 2 * * * /var/data/turnkey-service-php/scriptspod/backup_database.sh >/dev/null 2>&1
4 2 * * * /var/data/turnkey-service-php/scriptspod/bkup_file_rotation.sh >/dev/null 2>&1
```

Adjust this process (specifically the file rotation script) according to your needs. 

## Contact
Send questions and comments to andreas.mann@dkfz-heidelberg.de
