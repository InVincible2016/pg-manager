#! /bin/bash
set -ex

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# read config
source $SCRIPT_DIR/cluster-config.sh

mkdir -p $DATA_PATH
mkdir -p $ARCHIVE_PATH

initdb $DATA_PATH

sed -i -e "s|^#port.*|port=$PORT|" $PG_CONFIG
sed -i -e "s|^#listen_addresses.*|listen_addresses= '*'|" $PG_CONFIG
sed -i -e "s|^#unix_socket_directories.*|unix_socket_directories= '/tmp'|" $PG_CONFIG

sed -i -e "s|^#primary_conninfo.*|primary_conninfo= 'host=$REPLICA port=$PORT dbname=$DB_NAME user=rep_user connect_timeout=10'|" $PG_CONFIG

# WAL_LOG Shipping
sed -i -e "s|^#archive_mode.*|archive_mode= on|" $PG_CONFIG
sed -i -e "s|^#archive_command.*|archive_command= 'scp %p clzhong@$REPLICA:$ARCHIVE_PATH/%f'|" $PG_CONFIG
sed -i -e "s|^#restore_command.*|restore_command= 'cp $ARCHIVE_PATH/%f %p'|" $PG_CONFIG
sed -i -e "s|^#archive_cleanup_command.*|archive_cleanup_command= 'pg_archivecleanup -d $ARCHIVE_PATH %r 2>>cleanup.log'|" $PG_CONFIG

sed -i -e 's|^#hot_standby.*|hot_standby= on|' $PG_CONFIG

echo 'host    replication     rep_user        192.168.1.1/24            trust' >> $PG_HBA
echo 'host    all             all             192.168.1.1/24            trust' >> $PG_HBA

pg_ctl -D $DATA_PATH -l logfile start
psql -h /tmp postgres -p $PORT -c "CREATE ROLE rep_user with PASSWORD '$PASSWORD' LOGIN REPLICATION;"
psql -h /tmp postgres -p $PORT -c "CREATE ROLE admin_user with PASSWORD '$PASSWORD' LOGIN;"
psql -h /tmp postgres -p $PORT -c "CREATE DATABASE $DB_NAME with OWNER='admin_user';"