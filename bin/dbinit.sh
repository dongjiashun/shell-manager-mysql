#!/bin/bash
### Author : dongjiashun
### date : 2015-08-12
### Func : init mysql 


PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/dba/bin:/usr/local/mysql56/bin:/usr/local/px22/bin:/usr/local/pt22/bin:/usr/local/mysql55/bin:/usr/local/mariadb102/bin

export LANG=en_US.UTF-8
mem=2
slave=0

MUSER=dba


usage()
{
echo "usage:  
	sh  $0 -d dir -p port -m mem -s 1 -v version" 
echo "e.g.       
	sh  $0 -d /data1 -p 3999 -m 3 -s 1 -v mysql55" 
echo "
        -d      the base dir of mysql instance
"
echo "        
	-m	mem:default 2
		unit:GB"
echo "        
	-s	slave:default 0
		1:slave,0:master"
echo "       
	-v	version:default mysql55 
		optional:mysql55,mysql56"
}


while getopts p:d:v:s:m:h OPTION
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
       h)usage;
         exit 0
       ;;
       *)usage;
         exit 1
       ;;
   esac
done


if [ $versions = mysql55 ]
then
        version='55'
elif [ $versions = mysql56 ];then
        version='56'
elif [ $versions = mariadb102 ];then
        version='102'
else
        version='55'
fi
if [ $version = 102 ]
then
        daemon_dir=/usr/local/mariadb$version
else
	daemon_dir=/usr/local/mysql$version
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
		echo "[ERROR]: please specify data directory,exit!"
		exit 1
	fi

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
ip=`/sbin/ifconfig eth0 |grep "inet addr"| cut -f 2 -d ":"|cut -f 1 -d " "`
if [ -z $ip ]
then
      ip=`/sbin/ifconfig eth1 |grep "inet addr"| cut -f 2 -d ":"|cut -f 1 -d " "`
fi
echo $ip
}


function init_data()
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
max_allowed_packet             = 64M
max_connect_errors             = 1000000

# DATA STORAGE #binlog-format
datadir                        = $dir/mysql$port/
tmpdir 						   = $dir/mysql$port/
slave_load_tmpdir			   = $dir/mysql$port/

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
character-set-server=utf8
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
EOF

if [ $slave -eq 1 ]
then
	echo "read_only">>$data_dir/my${port}.cnf
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
        echo "$Port init ok"
	exit 0
else
	echo "$port init err"
	exit 1
fi
}

init_data
