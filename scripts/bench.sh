pgbench -h /tmp -p 5433 -U admin_user -i sharing_db

pgbench -h /tmp -p 5433 -U admin_user -c 10 -j 8 -t 10000 -P 1 sharing_db