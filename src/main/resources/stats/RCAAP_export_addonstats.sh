#!/bin/bash

# pgraca: paulo.graca@fccn.pt
# this script exports data from DS5x UMinho stats
# namely: views, downloads and workflows
# as a CSV files to be imported in DSpace Solr

# Current script dir
pushd "$(dirname "$0")" > /dev/null || exit
SCRIPTPATH=$(pwd)
popd > /dev/null || exit

DB_NAME="dspace"
# default current year
YEAR=$(date +'%Y')
# default current month
MONTH=$(date +'%m')

ALL_CHANGED=0
MONTH_CHANGED=0
YEAR_CHANGED=0

usage()
{
cat <<EOF
Usage: $(basename $0) [options]
 
This script exports data from DS5x UMinho stats,
namely: views, downloads and workflows
as CSV files (at /tmp directorty) to be imported as DSpace Solr Statistics

Options:

  --help            It will list the complete
                    guide for all supported
                    options.
  --dbname          Database name to use to Export data.
  --all             Extract all data.
  --year            Year to export (full year - YYYY).
  --month           Month to export (single month - MM).

Example:

   $(basename $0) [options]
 
EOF
}

while [ "$1" ]; do
  case "$1" in
    --help)
        usage
        exit 0
        ;;
    --dbname)
        shift
        DB_NAME="$1"
        ;;
    --all)
        shift
        ALL_CHANGED=1
        ;;
    --year)
        shift
        YEAR="$1"
        YEAR_CHANGED=1
        ;;
    --month)
        shift
        MONTH="$1"
        MONTH_CHANGED=1
        ;;
    *)
        echo "$(basename $0): invalid option $1" >&2
        echo "see --help for usage"
        exit 1
          ;;
  esac
  shift
done


echo "$(date +'%Y-%m-%d %H:%M:%S') - Starting exporting..."

# Loop for every file export_addon*.sql in the directory
for file in ${SCRIPTPATH}/export_addon*.sql; do
    MONTHS="01 02 03 04 05 06 07 08 09 10 11 12"
    YEARS="${YEAR}"

    if [ -e "$file" ]; then

        if [ "$ALL_CHANGED" -eq 0 ] && [ "$MONTH_CHANGED" -eq 1 ]; then
          if [[ "$MONTH" =~ ^[1-9]$ ]]; then
            MONTHS="0${MONTH}"
          elif [[ "$MONTH" =~ ^[0][1-9]$|^1[0-2]$ ]]; then
            MONTHS="${MONTH}"
          fi
        fi


        if [ "$ALL_CHANGED" -eq 0 ] && [ "$YEAR_CHANGED" -eq 1 ] && [ "$MONTH_CHANGED" -eq 1 ]; then
          if [[ "$YEAR" =~ ^[19]+[0-9]{2}$|^[20]+[0-9]{2}$ ]]; then
            YEARS="${YEAR}"
            MONTHS="${MONTH}"
          fi
        fi


        if [ "$ALL_CHANGED" -eq 1 ]; then
            # obtain start date and end date from stats.view
            IFS="|" read -r -a START_END_YEARS <<< "$(su - postgres -c "psql -d ${DB_NAME} -At -A -c \"SELECT TO_CHAR(MIN(date), 'YYYY'), TO_CHAR(MAX(date), 'YYYY') FROM stats.view\"")"


            start_year="${START_END_YEARS[0]}"
            end_year="${START_END_YEARS[1]}"

            for ((year=start_year; year<end_year; year++)); do
                YEARS+=" $year"
            done
        fi

        for year_i in $YEARS; do
            for month_i in $MONTHS; do
              YEAR_MONTH="${year_i}-${month_i}"
              echo "  - Exporting: ${YEAR_MONTH}"
              su - postgres -c "psql -d ${DB_NAME} <<< \"\$(sed 's/2009-12/${YEAR_MONTH}/g' ${file})\"" >> /dev/null
            done
        done


        if [ $? -eq 0 ]; then
            echo "Successfully exported content using $file"
        else
            echo "Error when exporting content from $file"
        fi
    else
        echo "No $file was found."
    fi
done

echo "$(date +'%Y-%m-%d %H:%M:%S') Ended - !!!You may check on /tmp for resulting files!!!"
