#!/bin/bash
### Author : dongjiashun
### date : 2015-08-12
### Func : init mysql 

### modify by dongjiashun
### support mysql5.7.40

PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/dba/bin:/usr/local/mysql56/bin:/usr/local/px22/bin:/usr/local/pt22/bin:/usr/local/mysql55/bin:/usr/local/mysql57/bin

export LANG=en_US.UTF-8
mem=10
slave=0

MUSER=dba


usage()
{
echo "usage:  
	sh  $0 -d <datadir> -p <port> -m <mem> -s <role> -v <version> -e <charset>" 
echo "e.g.       
	sh  $0 -d /data2 -p 3999 -m 10 -s 1 -v mysql57 -e utf8mb4" 
echo "
        -d      the datadir of the mysql

	-m	the innodb buffer pool of the mysql
                unit:GB
		default 1

	-s	the role of the mysql
		1:slave,0:master
                default:0

	-e	the charset of the mysql
		default is utf8mb4,
		valid:utf8|utf8mb4

	-v	the version of the mysql
                optional:mysql56,mysql57
		default mysql57 
"
}


while getopts p:d:v:s:m:e:h OPTION
do
   case "$OPTION" in
       p)port=$OPTARG
       ;;
       d)dir=$OPTARG
       ;;
       v)versions=$OPTARG
       ;;
       m)mem=$OPTARG
       ;;
       s)slave=$OPTARG
       ;;
       e)charset=$OPTARG
       ;;
       h)usage;
         exit 0
       ;;
       *)usage;
         exit 1
       ;;
   esac
done

if [  $versions = mysql55 ] || [  $versions = mysql56 ] || [  $versions = mysql57 ]
then
	daemon_dir=/usr/local/$versions
else
	echo "[ERROR]:valid value is mysql55|mysql56|mysql57"
	exit
fi


if [[ "$#" -eq 0 ]]
then
     usage
     exit 1
fi
if [ -z $dir ]
then
	if [ -d /data ]
	then
		dir=/data
	else
		echo "[error]: please check the datadir,exit..."
		exit
	fi

fi

if [ -z $charset ]
then
	charset=utf8mb4
fi


data_dir=$dir/mysql$port
log_dir=$dir/mysql$port

if_port_exit=`netstat -lnp|grep :$port|wc -l`
if [ $if_port_exit -gt 0 ]
  then
    echo "the $port exist"
    exit 1
fi


if [ -d $data_dir ]||[ -d $log_dir ]
then
        echo "the $data_dir $log_dir is exists,you must check"
	exit 1
else
        mkdir -p $data_dir   $log_dir
fi

getip()
{
#ip=`/sbin/ifconfig  |grep 'inet addr'|egrep 'Bcast:' |egrep 172| cut -f 2 -d ':' |cut -f 1 -d ' '|head -n1`
#ip=`/sbin/ifconfig  |grep 'inet addr'|egrep 'Bcast:' | cut -f 2 -d ':' |cut -f 1 -d ' '|head -n1`
#ip=`/sbin/ifconfig | grep 'eth1' -A 5 |grep -w 'inet' | awk -F' ' '{print $2}'`
ip=`/sbin/ifconfig | grep 'eth1: flags' -A 5 | grep -w 'inet' | awk -F' ' '{print $2}'`
if [ -z "$ip" ]
then
	echo "[ERROR] : can not get the host ip !!!"
	exit 1
fi
echo $ip
sleep 1

}


function init_data_56()
{
cat > $data_dir/my${port}.cnf  << EOF

##mysql cnf
[mysqld]

# GENERAL con#
user                           = $MUSER
port                           = $port
default_storage_engine         = InnoDB
socket                         = /tmp/mysql${port}.sock
pid_file                       = $dir/mysql$port/mysql.pid

#slave
#read_only
log-slave-updates

# MyISAM #
key_buffer              	= 32M
myisam_recover                 = FORCE,BACKUP

# SAFETY #
max_connect_errors             = 1000000

# DATA STORAGE #binlog-format
basedir                        = $daemon_dir
datadir                        = $dir/mysql$port/

# BINARY LOGGING #
log_bin                        = $dir/mysql$port/${port}-binlog
expire_logs_days               = 10
#sync_binlog                    = 1
relay-log=  $dir/mysql${port}/${port}-relaylog
#replicate-wild-do-table=test_url.%
#replicate-wild-do-table=gtest.%



# CACHES AND LIMITS #
tmp_table_size                 = 32M
max_heap_table_size            = 32M
query_cache_type               = 1
query_cache_size               = 0
max_connections                = 5000
#max_user_connections          = 200
thread_cache_size              = 512
open_files_limit               = 65535
table_definition_cache         = 4096
table_open_cache               = 4096
wait_timeout=7200
interactive_timeout=7200
#binlog-format=mixed
binlog-format=row
character-set-server=$charset
skip-name-resolve 
skip-character-set-client-handshake
back_log=1024


# INNODB #
innodb_flush_method            = O_DIRECT
innodb_data_home_dir = $dir/mysql$port/
innodb_data_file_path = ibdata1:100M:autoextend
innodb_log_group_home_dir=$dir/mysql$port/
innodb_log_files_in_group      = 3
innodb_log_file_size           = 1G
innodb_flush_log_at_trx_commit = 2
innodb_file_per_table          = 1
innodb_file_format=Barracuda 
innodb_support_xa=0

innodb_print_all_deadlocks=on

###perfermance vars
innodb_io_capacity=500
innodb_max_dirty_pages_pct=75
innodb_read_io_threads=16
innodb_write_io_threads=8
innodb_buffer_pool_instances=4
innodb_thread_concurrency=0

###double-master vars
#auto-increment-increment=2
#auto-increment-offset=1

# LOGGING #
log_error                      = $dir/mysql$port/${port}-error.log
#log_queries_not_using_indexes  = 1
slow_query_log                 = 1
slow_query_log_file            = $dir/mysql$port/${port}-slow.log
long_query_time=0.1

# new config dongjs wfq
log_bin_trust_function_creators=1
max_allowed_packet=1024M
innodb_strict_mode=0

EOF

if [ $slave -eq 1 ]
then
	#echo "read_only">>$data_dir/my${port}.cnf
	sed -i 's/#read_only/read_only/g' $data_dir/my${port}.cnf
fi

serverid=`getip|awk -F . '{print $1$2$3$4}'`
ipadd=`getip`
sid=$serverid$port
server_id=`echo $sid % 4000000000 | bc`
echo "server_id=$server_id">>$data_dir/my${port}.cnf
echo 'innodb_buffer_pool_size        = '$mem'G'>>$data_dir/my${port}.cnf
echo "skip-slave-start">>$data_dir/my${port}.cnf
echo "report-host=$ipadd">>$data_dir/my${port}.cnf
echo "report-port=$port">>$data_dir/my${port}.cnf

echo "### mysql_version=$versions" >> $data_dir/my${port}.cnf


echo "[mysql]
prompt = \\u@\\h:\\p [\\d]>" >> $data_dir/my${port}.cnf


$daemon_dir/scripts/mysql_install_db --user=$MUSER --basedir=$daemon_dir --datadir=$dir/mysql$port   --defaults-file=$dir/mysql$port/my${port}.cnf


if [ $? -eq 0 ]
then
        chown -R dba.dba $data_dir
        echo "$Port init ok"
	exit 0
else
	echo "$port init fail"
	exit 1
fi
}

init_data_57(){

### generate cnf file
#cat > $data_dir/my${port}.cnf  << EOF
cat > /tmp/my${port}.cnf  << EOF

##mysql cnf
[mysqld]

### general setting
user                           = $MUSER
port                           = $port
default_storage_engine         = InnoDB
socket                         = /tmp/mysql${port}.sock
pid_file                       = $dir/mysql$port/mysql.pid
datadir                        = $dir/mysql$port/
tmpdir                         = $dir/mysql$port/
slave_load_tmpdir              = $dir/mysql$port/
basedir                        = $daemon_dir

### add by 
#transaction_isolation            = READ-COMMITTED
transaction_isolation            = REPEATABLE-READ

### 0 or 1
explicit_defaults_for_timestamp  = 1

join_buffer_size                 = 8M
bulk_insert_buffer_size          = 64M 
group_concat_max_len             = 16K

secure_file_priv                 = ''
sql_mode                         = ''
##sql_mode = "STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER"

show_compatibility_56            = 1
secure_file_priv                 = ''
local_infile                     = OFF

read_buffer_size                 = 2M
read_rnd_buffer_size             = 8M
sort_buffer_size                 = 2M

# CACHES AND LIMITS #
tmp_table_size                 = 32M
max_heap_table_size            = 32M
max_prepared_stmt_count        = 1048570

query_cache_type               = 0
query_cache_size               = 0
query_cache_limit              = 2M
query_cache_min_res_unit       = 2K

max_connections                = 5000
max_user_connections           = 4000
thread_cache_size              = 512
thread_stack                   = 192K
open_files_limit               = 65535
table_definition_cache         = 4096
table_open_cache               = 4096
wait_timeout                   = 7200
interactive_timeout            = 7200

character_set_server             = utf8mb4
skip_name_resolve
back_log                       = 1024

read_only=OFF
super_read_only=OFF
key_buffer_size                = 32M
#myisam_recover                 = FORCE,BACKUP
max_connect_errors             = 1000000
#myisam_recover_options         = FORCE,BACKUP

lower_case_table_names=1
#auto-increment-increment=2
#auto-increment-offset=1

### performance schema ###
performance_schema                     = ON
performance_schema_digests_size        = 30000
max_digest_length                      = 4096
performance_schema_max_digest_length   = 4096
performance_schema_max_table_instances = 30000


### innodb setting
#innodb_page_size               = 8192
innodb_flush_method            = O_DIRECT
innodb_data_home_dir           = $dir/mysql$port/
innodb_data_file_path          = ibdata1:1G:autoextend
innodb_temp_data_file_path     = ibtmp1:1G:autoextend:max:2G
innodb_log_group_home_dir      = $dir/mysql$port/
innodb_log_files_in_group      = 3
#innodb_log_file_size          = 1G
innodb_log_buffer_size         = 32M

innodb_undo_directory          = $dir/mysql$port/
innodb_undo_logs               = 128
innodb_undo_tablespaces        = 3

innodb_purge_threads           = 4
innodb_large_prefix            = 1
innodb_thread_concurrency      = 64
innodb_print_all_deadlocks     = 1
innodb_sort_buffer_size        = 67108864


innodb_flush_log_at_trx_commit = 2
innodb_file_per_table          = 1
#innodb_file_format            = Barracuda 
#innodb_file_format_max         = Barracuda

### ON or OFF ?
innodb_support_xa                    = ON
innodb_open_files                    = 4096
innodb_online_alter_log_max_size     = 1G
innodb_autoinc_lock_mode             = 2


###perfermance vars
innodb_io_capacity             = 4000
innodb_io_capacity_max         = 5000
innodb_change_buffering        = all
innodb_max_dirty_pages_pct     = 75
innodb_read_io_threads         = 16
innodb_write_io_threads        = 16
innodb_buffer_pool_instances   = 8

### OFF or ON ?
innodb_buffer_pool_load_at_startup   = OFF
innodb_buffer_pool_dump_at_shutdown  = OFF
innodb_lru_scan_depth                = 2000
innodb_lock_wait_timeout             = 50

### 0 or 1 ?
innodb_flush_neighbors               = 0
innodb_stats_persistent_sample_pages = 32

innodb_buffer_pool_dump_pct          = 40
innodb_page_cleaners                 = 4
innodb_undo_log_truncate             = 1
innodb_max_undo_log_size             = 2G
innodb_purge_rseg_truncate_frequency = 128
binlog_gtid_simple_recovery          = 1
log_timestamps                       = SYSTEM
transaction_write_set_extraction     = MURMUR32


### log setting
log_error_verbosity            = 2
log_error                      = $dir/mysql$port/${port}-error.log
slow_query_log                 = 1
slow_query_log_file            = $dir/mysql$port/${port}-slow.log
long_query_time                = 0.1
log_timestamps                 = SYSTEM

log_slow_admin_statements              = 1
log_slow_slave_statements              = 1
#log_throttle_queries_not_using_indexes = 10
#min_examined_row_limit                 = 100

server_id                      = SERVERID
innodb_buffer_pool_size        = ${mem}G
skip_slave_start
report-host                    = REPORTHOST
report-port                    = REPORTPORT


### replication setting
slave_parallel_type            = logical_clock
slave_parallel_workers         = 0
slave_preserve_commit_order    = 1
slave_transaction_retries      = 128
slave_pending_jobs_size_max    = 1G
slave_rows_search_algorithms   = 'INDEX_SCAN,HASH_SCAN'

master_info_repository         = TABLE
relay_log_info_repository      = TABLE
relay_log                      = ${port}-relaylog
relay_log_recovery             = 1
max_relay_log_size             = 1G
relay_log_purge                = 1

sync_master_info               = 0
sync_relay_log                 = 0
sync_relay_log_info            = 0
slave_net_timeout              = 60

log_slave_updates              = 1


log_bin                        = ${port}-binlog
expire_logs_days               = 10
max_binlog_size                = 1G

binlog_cache_size              = 16M
sync_binlog                    = 1
binlog_rows_query_log_events   = 1


##replicate-wild-do-table=test_url.%
##replicate-wild-do-table=gtest.%

gtid_mode                      = on
enforce_gtid_consistency       = 1
binlog-format                  = row
#binlog_gtid_simple_recovery    = 1

### semi-sync settin
#plugin_dir=/usr/local/mysql57/lib/plugin
#plugin_load = "rpl_semi_sync_master=semisync_master.so;rpl_semi_sync_slave=semisync_slave.so"
#loose_rpl_semi_sync_master_enabled = 1
#loose_rpl_semi_sync_slave_enabled  = 1
#loose_rpl_semi_sync_master_timeout = 5000
# new config dongjs wfq
log_bin_trust_function_creators=1
max_allowed_packet=1024M
innodb_strict_mode=0


EOF

if [ $slave -eq 1 ]
then
        sed -i 's/read_only=OFF/read_only=ON/g' /tmp/my${port}.cnf
        sed -i 's/super_read_only=ON/super_read_only=OFF/g' /tmp/my${port}.cnf
fi

serverid=`getip|awk -F . '{print $1$2$3$4}'`
ipadd=`getip`
sid=$serverid$port
server_id=`echo $sid % 4000000000 | bc`
sed -i "s/SERVERID/$server_id/g" /tmp/my${port}.cnf
sed -i "s/REPORTHOST/$ipadd/g" /tmp/my${port}.cnf
sed -i "s/REPORTPORT/$port/g" /tmp/my${port}.cnf

echo "### mysql_version=$versions" >>/tmp/my${port}.cnf

echo "[mysql]
prompt = \\u@\\h:\\p [\\d]>" >>/tmp/my${port}.cnf


### 初始化 
$daemon_dir/bin/mysqld --defaults-file=/tmp/my${port}.cnf  --initialize
if [ $? -eq 0 ]
then
	echo "[note]: initialize ok"
else
	echo "[ERROR]:initialize fail"
	exit
fi
###
mv /tmp/my${port}.cnf $data_dir/my${port}.cnf
if [ $? -eq 0 ]
then
	echo "[note]: init data ok"
else
	echo "[ERROR]: init data fail"
	exit
fi
}



if [ $versions = "mysql55" ] || [ $versions = "mysql56" ]
then
	init_data_56
elif [ $versions = "mysql57" ];then
        init_data_57
fi


