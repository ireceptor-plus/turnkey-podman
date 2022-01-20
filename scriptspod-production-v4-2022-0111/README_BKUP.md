# Backup and Restore with turnkey and podman

The install script will create folders below PATH_BKUP_DIR, see podman.conf.sh.

incoming		backup_database.sh will create mongodb dump file here when running backup_database.sh
backup.daily	file rotation will put dumped file here on a regular day
backup.weekly   on saturday file will be placed here   
backup.monthly  on first day of month
restore         move any file to restore to this folder and use filename as argument in restore_database.sh

