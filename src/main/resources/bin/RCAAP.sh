#!/bin/bash

# pgraca: paulo.graca@fccn.pt
# this script executes other SHELL scripts
# it will receive a parameter corresponding with the command to execute

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

Options:

  --script          Script full path or script name to be executed.
                    name is script to be executed
                    without the "RCAAP" prefix
                    example: --script filter-media
                    to execute RCAAP-filter-media.sh


Example:

   $(basename $0) --script /dspace/bin/RCAAP-filter-media --n-days 10
 
EOF
}


case "$1" in
    --script)
        shift
        SCRIPT="$1"
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


# if name is called
if [[ ! -f "$SCRIPT" ]]; then
  SCRIPT="${SCRIPTPATH}/RCAAP-${SCRIPT}.sh"
fi

# Verify if script exists as a file
if [[ ! -f "$SCRIPT" ]]; then
    echo "Error executing ${SCRIPT}"
    usage
    exit 1
fi

echo "Executing $SCRIPT $@"
$SCRIPT $@