#!/bin/sh

# pgraca: paulo.graca@fccn.pt
# this script verifies if the exporting process of incremental files of dSpace packager works properly

# STATUS_FILE="/var/tmp/dspace/dspace_aip_dump_status"

# JAVA memory allocation
export JAVA_OPTS="-Xmx2048M -Xms512M -Dfile.encoding=UTF-8"

# Current script dir
SCRIPTPATH=$(dirname "$0")

# Default values
LOG_FILE="${SCRIPTPATH}/../log/rcaap_aip_packager.log"
N_DAYS="3"

usage()
{
cat <<EOF
Usage: $(basename "$0") [options]

This shell script exports AIP packages from dspace and verifies the 
result comparing it with archived items on database.

Options:

  --n-days       Number of days to consider for incremental.
                 Default '3'. If '-1' export all content

  --log-file     Log file location.
                 Default: '../log/rcaap_aip_export.log'

  --status-file  Export process status result file location.
                 Default: stdout

  --email        Email of eperson to use on export (Mandatory).

  --prefix       Handle prefix.
                 Default: what's defined in dspace.cfg

  --dir-target   Target directory, the place to save exported result.
                 Default: what's defined in dspace.cfg

Example:

   $(basename "$0")  --email test@example.com

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
        --email)
            shift
            EMAIL="$1"
            ;;
        --prefix)
            shift
            HANDLE_PREFIX="$1"
            ;;
        --dir-target)
            shift
            BACKUP_DIR="$1"
            ;;
        --status-file)
            shift
            STATUS_FILE="$1"
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

if [ -z "$EMAIL" ]; then
  echo "$(basename "$0"): email address is mandatory"
  exit 1
fi

if [ -z "$HANDLE_PREFIX" ]; then
  HANDLE_PREFIX=$(echo "$(${SCRIPTPATH}/dspace dsprop -property handle.prefix)")
fi

if [ -z "$BACKUP_DIR" ]; then
  BACKUP_DIR=$(echo "$(${SCRIPTPATH}/dspace dsprop -property org.dspace.app.itemexport.work.dir)/AIP")
  mkdir -p "$BACKUP_DIR"
fi

### yyyy-mm-dd ###
now="$(date +'%Y-%m-%d %H:%M:%S')"
echo "[$now] BEGIN" >> "${LOG_FILE}"

DB_USERNAME=$(echo "$(${SCRIPTPATH}/dspace dsprop -property db.username)")
DB_PASSWORD=$(echo "$(${SCRIPTPATH}/dspace dsprop -property db.password)")
DB_URL=$(echo "$(${SCRIPTPATH}/dspace dsprop -property db.url)")
DB_DATABASE=$(echo "${DB_URL}"|rev|cut -d'/' -f1|rev)
DB_PORT=$(echo "${DB_URL}"|rev|cut -d'/' -f2|cut -d':' -f1|rev)
DB_HOST=$(echo "${DB_URL}"|rev|cut -d'/' -f2|cut -d':' -f2|rev)

if [ "${N_DAYS}" -ge "0" ]; then

    HANDLES=$(echo "SELECT handle from handle WHERE resource_id IN (SELECT uuid FROM item WHERE last_modified >= date_trunc('day', current_date - interval '${N_DAYS}' DAY) and last_modified < date_trunc('day', current_date) AND in_archive = TRUE AND withdrawn = FALSE AND discoverable = TRUE ) and resource_type_id = 2 AND handle.handle IS NOT NULL;" | PGPASSWORD="${DB_PASSWORD}" psql -tU "${DB_USERNAME}" -h "${DB_HOST}" -p "${DB_PORT}" "${DB_DATABASE}")

    NUMBER_ITEMS=0

    for HANDLE in $HANDLES
    do
      FILENAME=$(echo ${HANDLE} | sed 's/\//\-/')
      # export AIP packages
      "${SCRIPTPATH}/dspace" packager -d -a -u -t AIP -e "${EMAIL}" -i "${HANDLE}" "${BACKUP_DIR}/ITEM@${FILENAME}.zip" >> "${LOG_FILE}"
      # first, retrieve the number of archived items processed
      NUMBER_ITEMS=$((NUMBER_ITEMS+1))
    done

    # find on the backup directory and count the number of just created files
    NUMBER_BACKUPS=$(find "$BACKUP_DIR" -mtime -1 ! -size 0 -type f -name "ITEM*.zip" | wc -l)

else

    # first, retrieve the number of archived items in the database associated with a prefix
    NUMBER_ITEMS=$(echo "SELECT count(*) FROM item LEFT JOIN handle ON item.uuid = handle.resource_id AND handle.resource_type_id = 2 AND handle.handle LIKE '${HANDLE_PREFIX}/%' WHERE in_archive=TRUE AND handle.handle IS NOT NULL;" | PGPASSWORD="${DB_PASSWORD}" psql -tU "${DB_USERNAME}" -h "${DB_HOST}" -p "${DB_PORT}" "${DB_DATABASE}")

    before="$(date +%s)"

    # export AIP packages
    "${SCRIPTPATH}/dspace" packager -d -a -u -t AIP -e "${EMAIL}" -i "${HANDLE_PREFIX}/0" "${BACKUP_DIR}/${HANDLE_PREFIX}-aip.zip" >> "${LOG_FILE}"

    # minutes difference between begin and end of process
    diff=$(perl -w -e "use POSIX; print ceil(($(date +%s)-$before)/60.0), qq{\n}")

    # find on the backup directory and count the number of just created files
    NUMBER_BACKUPS=$(find "$BACKUP_DIR" -mmin "-$diff" ! -size 0 -type f -name "ITEM*.zip" | wc -l)

    echo "The full process took: ${diff} minutes" >> "${LOG_FILE}"

fi

echo "Number of backups files found: ${NUMBER_BACKUPS}" >> "${LOG_FILE}"
echo "Number of items in the database to export: ${NUMBER_ITEMS}" >> "${LOG_FILE}"

# it will return 0 if error 1 if all ok
if [ "$NUMBER_BACKUPS" -ge "$NUMBER_ITEMS" ]; then
    if [ -z "$STATUS_FILE" ]; then
        echo "1"
    else
        echo "1" > "${STATUS_FILE}"
    fi
else
    if [ -z "$STATUS_FILE" ]; then
        echo "0"
    else
        echo "0" > "${STATUS_FILE}"
    fi
fi

### yyyy-mm-dd ###
now="$(date +'%Y-%m-%d %H:%M:%S')"
echo "[$now] END" >> "${LOG_FILE}"
