#!/bin/bash

# pgraca: paulo.graca@fccn.pt
# this script executes incremental filter media

# JAVA memory allocation
export JAVA_OPTS="-Xmx2048M -Xms512M -Dfile.encoding=UTF-8"


# Current script dir
pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd`
popd > /dev/null


LOG_FILE="${SCRIPTPATH}/../log/rcaap_filter_media.log"


usage()
{
cat <<EOF
Usage: $(basename $0) [options]
 
This shell script executes filter media from dspace
in an incremental way for all recently changed records.

Options:

  --n-days          Number of days to consider for incremental.
                    Default '5'

  --log-file        Log file location.
                    Default: '../log/rcaap_filter_media.log'

Example:

   $(basename $0) --log-file /dspace/log/rcaap_filter_media.log
 
EOF
} 

while [ "$1" ]; do
  case "$1" in
        --n-days)
            shift
            N_DAYS="$1"
            ;;
        --log-file)
            shift
            LOG_FILE="$1"
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


### yyyy-mm-dd ###
now="$(date +'%Y-%m-%d %H:%M:%S')"
echo "[$now] BEGIN" >> ${LOG_FILE}


DB_USERNAME=$(echo `${SCRIPTPATH}/dspace dsprop -property db.username`)
DB_PASSWORD=$(echo `${SCRIPTPATH}/dspace dsprop -property db.password`)
DB_URL=$(echo `${SCRIPTPATH}/dspace dsprop -property db.url`)
DB_DATABASE=$(echo ${DB_URL}|rev|cut -d'/' -f1|rev)
DB_PORT=$(echo ${DB_URL}|rev|cut -d'/' -f2|cut -d':' -f1|rev)
DB_HOST=$(echo ${DB_URL}|rev|cut -d'/' -f2|cut -d':' -f2|rev)

HANDLES=`echo "SELECT handle from handle WHERE resource_id IN (SELECT uuid FROM item WHERE last_modified >= date_trunc('day', current_date - interval '${N_DAYS}' DAY) and last_modified < date_trunc('day', current_date) AND in_archive = TRUE AND withdrawn = FALSE AND discoverable = TRUE ) and resource_type_id = 2 AND handle.handle IS NOT NULL;" | PGPASSWORD=${DB_PASSWORD} psql -tU ${DB_USERNAME} -h  ${DB_HOST} -p ${DB_PORT} ${DB_DATABASE}`

NUMBER_ITEMS=0

for HANDLE in $HANDLES
do
  #Filter media execution - /dspace/bin/dspace filter-media
  ${SCRIPTPATH}/dspace filter-media -v -i ${HANDLE} &>> ${LOG_FILE}
  #first, retrive the number of archived items processed
  NUMBER_ITEMS=$((NUMBER_ITEMS+1))
done

echo "Processed: ${NUMBER_ITEMS} handles" >> ${LOG_FILE}

### yyyy-mm-dd ###
now="$(date +'%Y-%m-%d %H:%M:%S')"
echo "[$now] END" >> ${LOG_FILE}