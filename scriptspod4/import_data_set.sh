#!/bin/bash
# Helper script to import data set in one step
# In your turnkey directory create a load_data folder. In load_data create a
# new directory for any new data set to import. Give that folder the name of your data set (here: FOLDER_NAME).
# In the data set folder create a file data_set_[FOLDER_NAME].sh 
# ..
# #!/bin/bash 
# # file containing repertoires
# repertoires_file="repertoires_xyz.yaml"
# # repertoire or ireceptor
# repertoire_data_type="repertoire"
# # (2)
# # airr, imgt or mixcr
# rearrangement_data_type="airr"
# # rearrangement files prefix 
# rearrangement_file_prefix="rearrangements_xyz_"
# # rearrangement filess postifx
# rearrangement_file_postfix=".tsv"
# 
# Then, from the turnkey path, call ./scriptspod/import_data_set.sh FOLDER_NAME 
#
ARG_COUNT=1
if [ $# -ne $ARG_COUNT ];
then
	echo "$0: wrong number of arguments ($# instead of $ARG_COUNT)"
	echo "usage: $0 [dir name in load_data containing data set]"
	exit
fi

SCRIPT_DIR=`dirname "$0"`

data_set_root_dir="load_data"
# e.g. athero_g07_09 this is also name of folder below data_set_file_path containing data files
data_set_dir=$1

# parent_dir="$(dirname "$data_set_file_path")"
# base_name="$(basename "$data_set_file_path")"

SCRIPT_DIR_FULL="$( readlink -f ${SCRIPT_DIR}  )";
POD_CONF_FILE="podman.conf.sh"
# read configuration for turnkey pod
. $SCRIPT_DIR_FULL/$POD_CONF_FILE

# 1) read data set 
log "import data set: ${data_set_dir}"
. $data_set_root_dir/$data_set_dir/data_set_${data_set_dir}.sh

# 2) import repertoire metadata
log "load repertoires: ${repertoires_file}"
. $SCRIPT_DIR_FULL/load_metadata.sh ${repertoire_data_type} $data_set_root_dir/$data_set_dir/$repertoires_file
#echo $SCRIPT_DIR_FULL/load_metadata.sh ireceptor $data_set_root_dir/$data_set_dir/$repertoires_file

# 3) import rearrangement files
log "load rearrangements.."
COUNTER=0
files=($(find ${data_set_root_dir}/${data_set_dir} -type f -name "${rearrangement_file_prefix}*"))
for item in ${files[*]}
do
  printf "   %s\n" $item
  . $SCRIPT_DIR_FULL/load_rearrangements.sh ${rearrangement_data_type} $item
  #echo $SCRIPT_DIR_FULL/load_rearrangements.sh ${rearrangement_data_type} $item
  COUNTER=$[$COUNTER +1]
done

# log "import done"
log "import for ${data_set_dir} done, rearrangement files: ${COUNTER}"
