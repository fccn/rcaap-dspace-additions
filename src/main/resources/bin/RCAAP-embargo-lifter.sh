#!/bin/sh

# pgraca: paulo.graca@fccn.pt
# this script executes embargo lifter by reindexing content

# JAVA memory allocation
export JAVA_OPTS="-Xmx2048M -Xms512M -Dfile.encoding=UTF-8"

# Current script dir
SCRIPTPATH=$(dirname "$0")

LOG_FILE="${SCRIPTPATH}/../log/rcaap_embargo_lifter.log"

usage()
{
cat <<EOF
Usage: $(basename "$0") [options]

This shell script executes filter media from dspace
in an incremental way for all recently changed records.

Options:

  --n-days          Number of days to consider for incremental.
                    Default '5'

  --log-file        Log file location.
                    Default: '../log/rcaap_embargo_lifter.log'

Example:

   $(basename "$0") --log-file /dspace/log/rcaap_embargo_lifter.log

EOF
} 

N_DAYS="1"

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
            echo "$(basename "$0"): invalid option $1" >&2
            echo "see --help for usage"
            exit 1
                  ;;
  esac
  shift
done

### yyyy-mm-dd ###
now="$(date +'%Y-%m-%d %H:%M:%S')"
echo "[$now] BEGIN" >> "${LOG_FILE}"

DB_USERNAME=$(echo "$(${SCRIPTPATH}/dspace dsprop -property db.username)")
DB_PASSWORD=$(echo "$(${SCRIPTPATH}/dspace dsprop -property db.password)")
DB_URL=$(echo "$(${SCRIPTPATH}/dspace dsprop -property db.url)")
DB_DATABASE=$(echo "${DB_URL}"|rev|cut -d'/' -f1|rev)
DB_PORT=$(echo "${DB_URL}"|rev|cut -d'/' -f2|cut -d':' -f1|rev)
DB_HOST=$(echo "${DB_URL}"|rev|cut -d'/' -f2|cut -d':' -f2|rev)

# processing bitstreams

# Issue https://github.com/DSpace/DSpace/issues/9764 - Proccess index-discovery fails when using DSO handle, we can revert this when fixed
#HANDLES=$(echo "SELECT handle FROM handle WHERE resource_id IN ( SELECT item_id FROM item2bundle AS i2b INNER JOIN bundle2bitstream AS b2b ON b2b.bundle_id = i2b.bundle_id INNER JOIN resourcepolicy AS rp ON rp.dspace_object = b2b.bitstream_id WHERE rp.resource_type_id = 0 AND ( (start_date >= date_trunc('day', current_date - interval '${N_DAYS}' DAY) AND start_date < date_trunc('day', current_date)) OR ((end_date >= date_trunc('day', current_date - interval '${N_DAYS}' DAY) AND end_date < date_trunc('day', current_date))) ) );" | PGPASSWORD="${DB_PASSWORD}" psql -tU "${DB_USERNAME}" -h "${DB_HOST}" -p "${DB_PORT}" "${DB_DATABASE}")
HANDLES=$(echo "SELECT item_id FROM item2bundle AS i2b inner join bundle2bitstream AS b2b ON b2b.bundle_id = i2b.bundle_id inner join resourcepolicy AS rp ON rp.dspace_object = b2b.bitstream_id WHERE rp.resource_type_id = 0 AND ( ( start_date >= date_trunc('day', current_date - interval '${N_DAYS}' DAY) AND start_date < date_trunc('day', current_date) ) OR (( end_date >= date_trunc('day', current_date - interval '${N_DAYS}' DAY) AND end_date < date_trunc('day', current_date) )) );" | PGPASSWORD="${DB_PASSWORD}" psql -tU "${DB_USERNAME}" -h "${DB_HOST}" -p "${DB_PORT}" "${DB_DATABASE}")

NUMBER_ITEMS=0

for HANDLE in $HANDLES
do
  #Filter media execution - /dspace/bin/dspace filter-media
  echo "... processing ${HANDLE}" >> "${LOG_FILE}"
  "${SCRIPTPATH}/dspace" index-discovery -i "${HANDLE}" >> "${LOG_FILE}"
  #first, retrieve the number of archived items processed
  NUMBER_ITEMS=$((NUMBER_ITEMS+1))
done

# processing items
# Issue https://github.com/DSpace/DSpace/issues/9764 - Proccess index-discovery fails when using DSO handle, we can revert this when fixed
#HANDLES=$(echo "SELECT handle FROM handle WHERE resource_id IN ( SELECT rp.dspace_object FROM resourcepolicy AS rp WHERE rp.resource_type_id = 2 AND ( (start_date >= date_trunc('day', current_date - interval '${N_DAYS}' DAY) AND start_date < date_trunc('day', current_date)) OR ((end_date >= date_trunc('day', current_date - interval '${N_DAYS}' DAY) AND end_date < date_trunc('day', current_date))) ));" | PGPASSWORD="${DB_PASSWORD}" psql -tU "${DB_USERNAME}" -h "${DB_HOST}" -p "${DB_PORT}" "${DB_DATABASE}")
HANDLES=$(echo "SELECT rp.dspace_object FROM resourcepolicy AS rp WHERE rp.resource_type_id = 2 AND ( ( start_date >= date_trunc('day', current_date - interval '${N_DAYS}' DAY) AND start_date < date_trunc('day', current_date) ) OR (( end_date >= date_trunc('day', current_date - interval '${N_DAYS}' DAY) AND end_date < date_trunc('day', current_date) )) );" | PGPASSWORD="${DB_PASSWORD}" psql -tU "${DB_USERNAME}" -h "${DB_HOST}" -p "${DB_PORT}" "${DB_DATABASE}")


for HANDLE in $HANDLES
do
  #Filter media execution - /dspace/bin/dspace filter-media
  echo "... processing ${HANDLE}" >> "${LOG_FILE}"
  "${SCRIPTPATH}/dspace" index-discovery -i "${HANDLE}" >> "${LOG_FILE}"
  #first, retrieve the number of archived items processed
  NUMBER_ITEMS=$((NUMBER_ITEMS+1))
done

echo "Processed: ${NUMBER_ITEMS} handles" >> "${LOG_FILE}"

### yyyy-mm-dd ###
now="$(date +'%Y-%m-%d %H:%M:%S')"
echo "[$now] END" >> "${LOG_FILE}"
