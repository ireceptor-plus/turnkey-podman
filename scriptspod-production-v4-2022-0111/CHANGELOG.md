# Changes

## 220120
- supports production-v4 branch from 2022-01-11 
- https with self signed or custom certificates
- custom apache configuration file for api container, if https is used
- batch import of several study files

## 210909
- turnkey version 4 for podman installations

## 210610

- default mongodb backup file name ends with ... dump.gzip
- podman.conf: BKUP_USES_ONLY_DIR_DAILY="1"; if set to 1, bkup_file_rotation.sh will only use backup.daily folder; by default, files are kept for 14 days in that folder, see script for details

## 210430

- adjustments for tests with debian 11 rc1 (Bullseye)
- shebang /bin/bash
- podman pull with full registry path
- run database dump process as root inside container (which is user running the container on host)

## 210427

- README changes

## 210421

- install script corrected unshare command

## 210420

- bkup_file_rotation.sh dont create empty folders
- update readme files 

## 210417 

- new configuration option DO_BKUP_FLAG absolute path to location of file which will trigger db backup, is checked in backup_database.sh
- created by load_ and update_scripts
