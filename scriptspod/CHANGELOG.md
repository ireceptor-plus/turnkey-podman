# Changes

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
