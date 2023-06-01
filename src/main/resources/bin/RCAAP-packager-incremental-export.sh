#!/bin/bash

# pgraca: paulo.graca@fccn.pt
# this script verifies if the exporting process of incremental files of dSpace packager works properly

RESULT_FILE_NAME="/var/tmp/dspace/dspace_aip_dump_status"
LOG_FILE="/var/log/dspace/export_aip.log"


# JAVA memory allocation
export JAVA_OPTS="-Xmx2048M -Xms512M -Dfile.encoding=UTF-8"


# Current script dir
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null


usage()
{
cat <<EOF
Usage: $(basename $0) [options]
 
This shell script exports AIP packages from dspace and verifies the 
result comparing it with archived itens on database.
 
Options:
 
  --email        Email of eperson to use on export.
 
  --prefix       Handle prefix.
 
  --dir_target   Target directory, the place to save exported result.

Example:

   $(basename $0)  --email test@example.com
 
EOF
} 

while [ "$1" ]; do
  case "$1" in
        --email)
            shift
            EMAIL="$1"
            ;;
        --dir_target)
            shift
            BACKUP_DIR="$1"
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "$(basename $0): invalid option $1" >&2
            echo "see --help for usage"
            exit 1
                  ;;
  esac
  shift
done

if [ -z "$EMAIL" ]; then
  echo "$(basename $0): email mandatory"
  exit 1
fi

if [ -z "$BACKUP_DIR" ]; then
  BACKUP_DIR=$(echo `${SCRIPTPATH}/dspace dsprop -property org.dspace.app.itemexport.work.dir`/AIP)
  mkdir -p $BACKUP_DIR
fi

### yyyy-mm-dd ###
now="$(date +'%Y-%m-%d %H:%M:%S')"
echo "\n[$now] BEGIN" >> ${LOG_FILE}

HANDLES=`echo "SELECT handle from handle WHERE resource_id IN (SELECT item_id FROM item WHERE last_modified >= date_trunc('day', current_date - interval '3' DAY) and last_modified < date_trunc('day', current_date) AND in_archive = TRUE AND withdrawn = FALSE AND discoverable = TRUE ) and resource_type_id = 2 AND handle.handle IS NOT NULL;" | psql -tU postgres dspace|sed 's| ||g'`

NUMBER_ITEMS=0

for HANDLE in $HANDLES
do
  #export AIP packages
  ${SCRIPTPATH}/dspace packager -d -a -u -t AIP -e ${EMAIL} -i ${HANDLE} ${BACKUP_DIR}/ITEM@${HANDLE//\//-}.zip &>> ${LOG_FILE}
  #first, retrive the number of archived items processed
  NUMBER_ITEMS=$((NUMBER_ITEMS+1))
done

#find on the backup directory and count the number of just created files
NUMBER_BACKUPS=(`find $BACKUP_DIR -mtime -1 ! -size 0 -type f -name "ITEM*.zip" | wc -l`)

if [ "$NUMBER_BACKUPS" -ge "$NUMBER_ITEMS" ]; then
    echo "1" > ${RESULT_FILE_NAME}
else
    echo "0" > ${RESULT_FILE_NAME}
fi

### yyyy-mm-dd ###
now="$(date +'%Y-%m-%d %H:%M:%S')"
echo "[$now] END" >> ${LOG_FILE}
