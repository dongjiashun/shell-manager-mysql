#!/bin/bash
### Author : hzdongjiashun
### Date : 2015-05-22
### Func : init redis 2.8 ,will support redisCluster later
# Backward compatibility,if no role,default will be Redis
### update by dongjiashun
### support redis 3.0
### [2018-02-28] support redis3.2

PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/dba/bin:/usr/local/mysql56/bin:/usr/local/px22/bin:/usr/local/pt22/bin:/usr/local/redis30/bin:/usr/local/redis32/bin

export LANG=en_US.UTF-8
daemon_dir=/usr/local/redis30

function  usage()
{
        echo "usage:		$0 OPTIION
		-p port 
		-m memory unit:GB
		-r role support redis rediscluster, default is redis
		-v version  support 3.2 3.0,default is 3.2
		-d dir default value:/home/dba

" 	
	echo "i.e."
        echo "		$0 -p 6999 -m 4 " 
        echo "		$0 -p 6999 -m 4 -r redis -v 3.2 -d /data " 
        echo "		$0 -p 6999 -m 4 -r rediscluster -v 3.2 -d /data " 
}

if [[ "$#" -eq 0 ]]
then
     usage
     exit 1
fi


function init_redisCluster3x()
{
data_dir=$BDIR/redis$port
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
### redis 3.0/3.2 cluster configuration 
### 6000-6299
################################ GENERAL ##################################### 
daemonize yes 
pidfile $BDIR/redis$port/redis.pid
port $port
tcp-backlog 511 
#timeout 30 
timeout 0
tcp-keepalive 0 

# bind 192.168.1.100 10.0.0.1 
# bind 127.0.0.1 
unixsocket /tmp/redis$port.sock
unixsocketperm 755 

# debug verbose notice warning 
loglevel notice 
logfile $BDIR/redis$port/redis.log
databases 16 

################################# SNAPSHOTTING ################################ 
#save 900 1 
#save 300 10 
#save 60 10000 
save \"\" 
stop-writes-on-bgsave-error yes 
rdbcompression yes 
rdbchecksum yes 
dbfilename dump${port}.rdb
dir $BDIR/redis$port

################################# REPLICATION ################################# 
# slaveof <masterip> <masterport> 
# repl-ping-slave-period 10 
# repl-timeout 60 
# min-slaves-to-write 3 
# min-slaves-max-lag 10 
#repl-backlog-size 1gb 
repl-backlog-ttl 0 
slave-serve-stale-data yes 
slave-read-only yes 
repl-disable-tcp-nodelay no 
slave-priority 100 

################################## SECURITY ################################### 
# requirepass foobared 
# rename-command CONFIG "" 
rename-command flushdb  dbaflushdb 
rename-command flushall dbaflushall 
rename-command shutdown dbashutdown 
### do not rename,or failover do not work
#rename-command config   dbaconfig
###requirepass $password
###masterauth $password

################################### LIMITS #################################### 
# maxmemory-policy noeviction 
# maxmemory-samples 5 
maxclients 5000 
maxmemory ${memory}gb

############################## APPEND ONLY MODE ############################### 
appendonly yes 
appendfilename appendonly.aof
# appendfsync always everysec no 
appendfsync everysec 
no-appendfsync-on-rewrite yes 
auto-aof-rewrite-percentage 100 
auto-aof-rewrite-min-size 10G 
aof-load-truncated yes 
aof-rewrite-incremental-fsync yes

################################ LUA SCRIPTING ############################### 
lua-time-limit 5000 

################################ REDIS CLUSTER ############################### 
cluster-enabled yes
cluster-config-file nodes.conf 
cluster-node-timeout 15000 
cluster-slave-validity-factor 10 
cluster-migration-barrier 1 
cluster-require-full-coverage yes 

################################## SLOW LOG ################################### 
slowlog-log-slower-than 1000 
slowlog-max-len 1024 

################################ LATENCY MONITOR ############################## 
latency-monitor-threshold 0 

############################# Event notification ############################## 
# PUBLISH __keyspace@0__:foo del 
# PUBLISH __keyevent@0__:del foo 
notify-keyspace-events \"\" 

############################### ADVANCED CONFIG ############################### 
hash-max-ziplist-entries 512 
hash-max-ziplist-value 64 
list-max-ziplist-entries 512 
list-max-ziplist-value 64 
set-max-intset-entries 512 
zset-max-ziplist-entries 128 
zset-max-ziplist-value 64 
hll-sparse-max-bytes 3000 
activerehashing yes 
client-output-buffer-limit normal 0 0 0 
client-output-buffer-limit slave 0 0 0 
client-output-buffer-limit pubsub 32mb 8mb 60 
hz 10 

###redis_version=$REDISVER
">$data_dir/redis$port.cnf
echo " init done"
fi
}


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

if [ -z $role ]
then
        role="redis"
fi


if [ -z $version ]
then
        version=3.0
fi

if [ $role == rediscluster ]
then
	if [ -z $version ]
	then
		version=3.0
	elif [ $version == 2.8 ];then
		echo "redis2.8 does not support cluster,transfer to 3.0 "
                version=3.0
	fi
fi
if [ $version = "3.0" ]
then
	REDISVER=redis30
elif [ $version = "3.2" ];then
	REDISVER=redis32
fi




if [ $role != "redis"  -a $role != "rediscluster" ];
then
        echo "Unknown Role,Only support 'redis,rediscluster'!"
        exit 1
fi 


if [ -z $port ]
then
        echo "you must have a port!"
        usage
        exit 3
fi

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
password=`echo redis_ewtonline_$port | md5sum | cut -c 1-16`
if [ -z $password ]
then
        echo "you must have a password!"
        usage
        exit 2
fi


init_data3x()
{
###install_redis3x
###port=$1
###password=$2

data_dir=$BDIR/redis$port
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
### Redis2.8 configuration file example
### 6300-6899

daemonize yes
pidfile $BDIR/redis$port/redis.pid
port $port
unixsocket /tmp/redis$port.sock
unixsocketperm 755
timeout 0

#debug verbose notice warning
loglevel notice
logfile $BDIR/redis$port/redis.log

databases 16
#repl-backlog-size 2gb
#repl-backlog-ttl 0


#strong monitor 
stop-writes-on-bgsave-error no
rdbcompression yes
rdbchecksum yes
dbfilename dump$port.rdb
dir $BDIR/redis$port

# slaveof <masterip> <masterport>
# masterauth <master-password>
##slave-serve-stale-data yes
##slave-read-only yes
## repl-ping-slave-period 10
## repl-timeout 60

slave-priority 10
maxclients 10000
maxmemory ${memory}gb
# 
# volatile-lru -> remove the key with an expire set using an LRU algorithm
# allkeys-lru -> remove any key accordingly to the LRU algorithm
# volatile-random -> remove a random key with an expire set
# allkeys-random -> remove a random key, any key
# volatile-ttl -> remove the key with the nearest expire time (minor TTL)
# noeviction -> don't expire at all, just return an error on write operations
# 
# maxmemory-policy volatile-lru
maxmemory-policy allkeys-lru
maxmemory-samples 3
appendonly yes

# appendfsync always
appendfsync everysec
# appendfsync no

#no-appendfsync-on-rewrite yes
no-appendfsync-on-rewrite no

auto-aof-rewrite-percentage 100
#auto-aof-rewrite-min-size 20G
auto-aof-rewrite-min-size 64mb

# The following time is expressed in microseconds, so 1000000 is equivalent
#slowlog-log-slower-than 1000
slowlog-log-slower-than 10000

slowlog-max-len 1024

#saving memory
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-entries 512
list-max-ziplist-value 64
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
activerehashing yes

# normal -> normal clients
# slave  -> slave clients and MONITOR clients
# pubsub -> clients subcribed to at least one pubsub channel or pattern
#
client-output-buffer-limit normal 0 0 0
#client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit slave 0 0 0
client-output-buffer-limit pubsub 32mb 8mb 60

rename-command flushdb dbaflushdb
rename-command flushall dbaflushall
rename-command shutdown dbashutdown
#rename-command config   dbaconfig
requirepass $password
masterauth $password
###redis_version=$REDISVER
">$data_dir/redis$port.cnf
echo " init done"
fi
}


if [ $role == 'redis' ] 
then
	if [ $version == 3.0 ] || [ $version == 3.2 ]
	then
	        ###init_data3x $port $password  $REDISVER
	        init_data3x 
	else
                ###init_data3x $port $password redis32
                init_data3x 
	fi
elif [ $role == "rediscluster" ];then
	if [ $version == 3.0 ] || [ $version == 3.2 ]
	then
		###init_redisCluster3x $REDISVER
		init_redisCluster3x 
	fi

fi
