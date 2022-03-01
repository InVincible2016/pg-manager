#! /bin/bash
set -ex

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# read config
source $SCRIPT_DIR/cluster-config.sh

mkdir -p $ARCHIVE_PATH

pg_basebackup -D $DATA_PATH --wal-method=stream -h $PRIMARY -p $PORT -U rep_user -P -c fast

sed -i -e "s|^#port.*|port=$PORT|" $PG_CONFIG
sed -i -e 's|^#hot_standby.*|hot_standby= on|' $PG_CONFIG
sed -i -e "s|^#listen_addresses.*|listen_addresses= '*'|" $PG_CONFIG
sed -i -e "s|^#unix_socket_directories.*|unix_socket_directories= '/tmp'|" $PG_CONFIG
sed -i -e "s|^#archive_command.*|archive_command= 'scp %p clzhong@$PRIMARY:~/$ARCHIVE_PATH/%f'|" $PG_CONFIG
sed -i -e "s|^#primary_conninfo.*|primary_conninfo= 'host=$PRIMARY port=$PORT dbname=$DB_NAME user=rep_user connect_timeout=10'|" $PG_CONFIG

touch $DATA_PATH/standby.signal

echo 'host    replication     rep_user        192.168.1.1/24            trust' >> $PG_HBA
echo 'host    all             all             192.168.1.1/24            md5' >> $PG_HBA

pg_ctl -D $DATA_PATH -l logfile start
