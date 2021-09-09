#!/bin/bash
CURRENTUSER=$(who | awk 'NR==1{print $1}')
echo $CURRENTUSER
if [ ! -e .mongodb_data  ];then
	mkdir .mongodb_data
	chown $CURRENTUSER:$CURRENTUSER .mongodb_data
	podman unshare chown 999:999 -R .mongodb_data
else
	echo "db data directory exists"
	exit
fi	
