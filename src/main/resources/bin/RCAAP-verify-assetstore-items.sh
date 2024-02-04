#!/bin/sh

# pgraca: paulo.graca@fccn.pt
# this script verifies if bitstream files in the assetstore have metadata defined in the database

# dependencies: find, diff, psql/postgresql, sed, grep, sort, cat

# Current script dir
SCRIPTPATH=$(dirname "$0")

LOG_FILE="${SCRIPTPATH}/../log/rcaap_verify_assetstore.log"

usage()
{
cat <<EOF
Usage: $(basename "$0") [options]

This shell script exports AIP packages from dspace and verifies the 
result comparing it with archived items in the database.

Options:

  --log-file     Log file location.
                 Default: '../log/rcaap_verify_assetstore.log'

  --dir_source   The assetstore based directory
                 Default: what's defined in dspace.cfg

Example:

   $(basename "$0")  --dir_source /srv/dspace/assetstore

EOF
} 


while [ "$1" ]; do
  case "$1" in
        --log-file)
            shift
            LOG_FILE="$1"
            ;;
        --dir_source)
            shift
            BASE_DIR="$1"
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

if [ -z "$BASE_DIR" ]; then
  BASE_DIR=$(echo "$(${SCRIPTPATH}/dspace dsprop -property assetstore.dir)")
fi

BITSTREAMS_ASSETSTORE_ID=$(cat /proc/sys/kernel/random/uuid)
BITSTREAMS_DB_ID=$(cat /proc/sys/kernel/random/uuid)

# find only for files and output their name sorted
find "$BASE_DIR" -type f -printf '%f\n'|sort 1>/tmp/${BITSTREAMS_ASSETSTORE_ID}.txt

DB_USERNAME=$(echo "$(${SCRIPTPATH}/dspace dsprop -property db.username)")
DB_PASSWORD=$(echo "$(${SCRIPTPATH}/dspace dsprop -property db.password)")
DB_URL=$(echo "$(${SCRIPTPATH}/dspace dsprop -property db.url)")
DB_DATABASE=$(echo "${DB_URL}"|rev|cut -d'/' -f1|rev)
DB_PORT=$(echo "${DB_URL}"|rev|cut -d'/' -f2|cut -d':' -f1|rev)
DB_HOST=$(echo "${DB_URL}"|rev|cut -d'/' -f2|cut -d':' -f2|rev)

# find all bitstream and output their internal_id trimming all spaces
echo "SELECT internal_id FROM bitstream ORDER BY internal_id;" | PGPASSWORD="${DB_PASSWORD}" psql -tU "${DB_USERNAME}" -h "${DB_HOST}" -p "${DB_PORT}" "${DB_DATABASE}" 1>/tmp/${BITSTREAMS_DB_ID}.txt

# compare the files - check if there is any file in the assetstore that isn't in the database
diff -b --ignore-blank-lines /tmp/${BITSTREAMS_ASSETSTORE_ID}.txt /tmp/${BITSTREAMS_DB_ID}.txt| grep -v "^---" | grep -v "^[0-9c0-9]" | grep -v "^>" |sed "s|<|Only in assetstore:|g"|sed "s|>|Only in database:|g" 1>"${LOG_FILE}"
