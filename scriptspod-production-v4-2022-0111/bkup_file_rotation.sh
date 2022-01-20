#!/bin/bash
# Julius Zaromskis
# Backup rotation
# https://nicaw.wordpress.com/2013/04/18/bash-backup-rotation-script/

SCRIPT_DIR=`dirname "$0"`
SCRIPT_DIR_FULL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
POD_CONF_FILE="podman.conf.sh"
# read configuration for turnkey pod
. $SCRIPT_DIR_FULL/$POD_CONF_FILE

# Storage folder where to move backup files
# Must contain backup.monthly backup.weekly backup.daily folders
# storage=/home/backups/your_website_name
storage=${PATH_BKUP_DIR}/${POD_NAME_SVC}

# Source folder where files are backed
source=$storage/incoming

# Destination file names %d-%m-%Y"
date_daily=`date +"%Y-%m-%d"`
#date_weekly=`date +"%V sav. %m-%Y"`
#date_monthly=`date +"%m-%Y"`

# Get current month and week day number
month_day=`date +"%d"`
week_day=`date +"%u"`

# Optional check if source files exist. Email if failed.
#if [ ! -f $source/archive.tgz ]; then
#     ls -l $source/ | mail $sysadmin_email \
#	 -s "[${host_name}-bkup script] Daily backup failed! Please check for missing files."
#fi

if [ "$(ls -A $source)" ]; then
     echo "File found..."
else
    exit;
fi

# It is logical to run this script daily. We take files from source folder and move them to
# appropriate destination folder

# On first month day do
if [ "$month_day" -eq 1 ] ; then
  destination=${storage}/backup.monthly/$date_daily
else
  # On saturdays do
  if [ "$week_day" -eq 6 ] ; then
    destination=${storage}/backup.weekly/$date_daily
  else
    # On any regular day do
    destination=${storage}/backup.daily/$date_daily
  fi
fi

# override if set in podman.conf to use only daily dir
if [[ "$BKUP_USES_ONLY_DIR_DAILY" == "1" ]]; then
    destination=${storage}/backup.daily/$date_daily
fi

# Move the files
mkdir $destination
mv -v $source/* $destination

# daily - keep for 14 days
find $storage/backup.daily/ -maxdepth 1 -mtime +14 -type d -exec rm -rv {} \;

# weekly - keep for 60 days
find $storage/backup.weekly/ -maxdepth 1 -mtime +60 -type d -exec rm -rv {} \;

# monthly - keep for 300 days
find $storage/backup.monthly/ -maxdepth 1 -mtime +300 -type d -exec rm -rv {} \;

echo "done"
