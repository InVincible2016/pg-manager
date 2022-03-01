#! /bin/bash
set -ex

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# read config
source $SCRIPT_DIR/cluster-config.sh

pg_ctl -D $DATA_PATH -l logfile stop