#!/bin/bash

# pgraca: paulo.graca@fccn.pt
# this script executes incremental filter media

LOG_FILE="/var/log/dspace/filter_media.log"


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
 
This shell script executes filter media from dspace
in an incremental way for all recently changed records.
 

Example:

   $(basename $0)
 
EOF
} 

while [ "$1" ]; do
  case "$1" in
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
echo "\n[$now] BEGIN" >> ${LOG_FILE}

HANDLES=`echo "SELECT handle from handle WHERE resource_id IN (SELECT item_id FROM item WHERE last_modified >= date_trunc('day', current_date - interval '5' DAY) and last_modified < date_trunc('day', current_date) AND in_archive = TRUE AND withdrawn = FALSE AND discoverable = TRUE ) and resource_type_id = 2 AND handle.handle IS NOT NULL;" | psql -tU postgres dspace|sed 's| ||g'`

NUMBER_ITEMS=0

for HANDLE in $HANDLES
do
  #Filter media execution - /dspace/bin/dspace filter-media
  ${SCRIPTPATH}/dspace filter-media -v -i ${HANDLE} &>> ${LOG_FILE}
  #first, retrive the number of archived items processed
  NUMBER_ITEMS=$((NUMBER_ITEMS+1))
done

echo "\n Processed: ${NUMBER_ITEMS} handles"

### yyyy-mm-dd ###
now="$(date +'%Y-%m-%d %H:%M:%S')"
echo "[$now] END" >> ${LOG_FILE}