# # airr, imgt or mixcr
# rearrangement_data_type="airr"
# # rearrangement files prefix 
# rearrangement_file_prefix="rearrangements_xyz_"
# # rearrangement filess postifx
# rearrangement_file_postfix=".tsv"
# 
# Then, from the turnkey path, call ./scriptspod/import_data_set.sh FOLDER_NAME 


function confirm () {
	local msg=$1
    echo "confirm (y/n): $msg"
    read in_confirm
	if [ $in_confirm != "y"  ]; then
		return 255
	else
		return 0	
	fi
}

ARG_COUNT=0
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
. $SCRIPT_DIR_FULL/colors.sh

# folders with data set for batch import  
#DATA_SET_FOLDER_LIST=( "athero_g07_09" "omega_w02" "omega_w03" "omega_w04" "omega_w05" "omega_w07" );
DATA_SET_FOLDER_LIST=( "omega_w03" );

# list of study_id to generate stats information 
LOAD_STATS_ID_LIST=( "2YNBAIAJ" );
# LOAD_STATS_ID_LIST=( "6R5ENPH5" "ADFPAKLS" "2YNBAIAJ" "TAZQRXHQ" "NYEKYTEN" "BIJ6B5TC" );

echo "These data sets are configured for import"
for i in "${DATA_SET_FOLDER_LIST[@]}"
do
	printf "${Red}-  $i"
    echo ""
done

printf $Color_Off

confirm "do you want to start batch import ?"
if [ $? != 0  ]; then
	echo "import canceled"
	exit
fi

echo "------------------------------------------"

for i in "${DATA_SET_FOLDER_LIST[@]}"
do
	echo "------------------------------------------"
	printf "${Green} -------------------- import $i"
	
	printf $Color_Off
	echo " "
	scriptspod/import_data_set.sh $i
done

echo "load stats .."


for i in "${LOAD_STATS_ID_LIST[@]}"
do
	printf "${Green} --------------------- load stats for study_id $i "
	printf $Color_Off
	echo " "
	scriptspod/load_stats.sh $i
done

echo "------------------------------------------"
echo batch import end.

