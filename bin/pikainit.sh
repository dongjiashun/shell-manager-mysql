#!/bin/bash
### Author : hzdongjiashun
### Date : 2015-05-22
### Func : init pika 2.2
# Backward compatibility,if no role,default will be Redis

PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/dba/bin:/usr/local/mysql56/bin:/usr/local/px22/bin:/usr/local/pt22/bin:/usr/local/redis30/bin:/usr/local/pika23/bin

export LANG=en_US.UTF-8

function  usage()
{
        echo "usage:		$0 OPTIION
		-p port valid value: [ 6990 - 6999 ] 
		-m memory unit:GB
		-r role pika
		-v version  support pika2.3,default is pika2.3
		-d dir default value:/data1

" 	
	echo "i.e."
        echo "		$0 -p 5900 -m 1 " 
        echo "		$0 -p 5900 -m 1  -v 2.2  -d /data   [ -r pika ]" 
        echo "		$0 -p 5900 -m 1 -v 2.2 [ -d /data ]  [ -r pika ]" 
}

if [[ "$#" -eq 0 ]]
then
     usage
     exit 1
fi

while getopts p:m:d:v:r:h OPTION
do
   case "$OPTION" in
       p)port=$OPTARG
       ;;
       d)BDIR=$OPTARG
       ;;
        m)memory=$OPTARG
       ;;
	r)role=$OPTARG
       ;;
        v)version=$OPTARG
       ;;
       h)usage
         exit 0
       ;;
       *)
           usage      
           exit 1
          ;;
   esac
done

role=pika

if [ -z $version ]
then
        version=2.3
fi

if [ -z $port ]
then
        echo "you must have a port!"
        usage
        exit 3
else
	if [ $port -lt 9000 ] || [ $port -ge 10000  ]
	then
		echo "invalid port,please check!"
		usage
		exit 1
	fi
fi

maxmemory=`echo ${memory}*1024*1024*1024|bc`


if [ -z $BDIR ]
then
	if [ -d /data1 ]
	then
		BDIR=/data1
	elif [ -d /data ];then
		BDIR=/data
	else
                BDIR=/home/dba
	fi
fi

###password=`openssl rand -base64 9`
password=`echo pika_ewtonline_$port | md5sum | cut -c 1-16`
if [ -z $password ]
then
        echo "you must have a password!"
        usage
        exit 2
fi


### pika2.3
init_data23(){
port=$1
password=$2
data_dir=$BDIR/pika$port
if_port_exit=`netstat -lnp|grep :$port|wc -l`
if [ $if_port_exit -gt 0 ]
then
	echo "[Warning] : The $port already exists,please check"
	exit 1
fi

if [ -d $data_dir ]
then
	echo "[Warning] : The $data_dir  already  exists,please check"
	exit 1
else
	mkdir -p $data_dir 
	echo "

# Pika port
port : $port
# Thread Number
thread-num : 4
# Sync Thread Number
sync-thread-num : 6
# Item count of sync thread queue
sync-buffer-size : 10
# Pika log path
log-path : ./log/
# Pika glog level: only INFO and ERROR
loglevel : INFO
# Pika db path
db-path : ./db/
# Pika write-buffer-size
write-buffer-size : $maxmemory
# Pika timeout
timeout : 60
# Requirepass
requirepass : pika21dminDBAG
# Userpass
userpass : $password

### repass
#masterauth: 07960d1c2e03c555

# User Blacklist
userblacklist : FLUSHALL,SHUTDOWN,FLUSHDB
# Dump Prefix
dump-prefix : ${port}-
# daemonize  [yes | no]
daemonize : yes
# Dump Path
dump-path : ./dump/
# pidfile Path
pidfile : ./pika${port}.pid
# Max Connection
maxclients : 20000
# the per file size of sst to compact, defalut is 2M
target-file-size-base : 104857600
# Expire-logs-days
expire-logs-days : 7
# Expire-logs-nums
expire-logs-nums : 100
# Root-connection-num
root-connection-num : 6
# Slowlog-log-slower-than
slowlog-log-slower-than : 10000
# slave-read-only(yes/no, 1/0)
slave-read-only : true
# Pika db sync path
db-sync-path : ./dbsync/
# db sync speed(MB) max is set to 125MB, min is set to 0, and if below 0 or above 125, the value will be adjust to 125
db-sync-speed : 12
# network interface
# network-interface : eth1
# replication
# slaveof : master-ip:master-port

###################
## Critical Settings
###################
# binlog file size: default is 100M,  limited in [1K, 2G]
binlog-file-size : 536870912
# Compression
compression : snappy
# max-background-flushes: default is 1, limited in [1, 4]
max-background-flushes : 1
# max-background-compactions: default is 1, limited in [1, 4]
max-background-compactions : 1
# max-cache-files default is 5000
max-cache-files : 5000

###pika_version=pika$version
">$data_dir/pika$port.cnf
echo " init done"
fi
}

if [ $version = 2.3 ]
then
	init_data23 $port $password
fi



