#!/bin/bash
### Author : hzdongjiashun
### Date : 2015-05-22
### Func : start redis or stop redis


PATH=$PATH:/usr/local/redis30/bin:/usr/local/redis32/bin:/usr/local/mysql56/bin
. /etc/profile
export LANG=en_US.UTF-8


BREDIS=/usr
rediserver30=$BREDIS/bin/redis-server
rediserver32=$BREDIS/bin/redis-server
if [ ! -f $redis ]
then
	if [ ! -f $redis2 ];then
		echo "[Warning] : Not found redis-cli command,please check"
		exit 1
	fi
fi


function  usage()
{
	echo "usage:  sh  $0 -p port -a stop|start" 
}

if [[ "$#" -ne 4 ]]  
then
     usage
     exit 1
fi


while getopts p:h:a: OPTION
do
   case "$OPTION" in
       p)port=$OPTARG
       ;;
       a)action=$OPTARG
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

for DATADIR in  /data/ /data1/ /data2/ /data3/
do
    FILE=`find $DATADIR -name redis${port}.cnf 2>/dev/null`
    if [ AA"`echo $FILE | grep redis${port}.cnf`" != AA ]
    then
        datadir=`echo $FILE | sed  "s/redis${port}.cnf//g"`
	if [ AA"`cat $FILE | egrep 'redis_version=redis28'`" != AA ]
	then
		version=redis28	
	elif [ AA"`cat $FILE | egrep 'redis_version=redis30'`" != AA ];then
		version=redis30
        elif [ AA"`cat $FILE | egrep 'redis_version=redis32'`" != AA ];then
		version=redis32
	fi
	rediserver=/usr/bin/redis-server
	rediscli=/usr/bin/redis-cli
        break
    fi
done

if [ "$action" == 'start' ]
then
	if_port_exitp=`netstat  -g -lnp|grep :$port|wc -l`
	if_port_exit=`  ps -ef|grep redis-server|grep redis${port}.cnf|grep -v grep |wc -l  `
	if [ $if_port_exit -gt 0 ] || [ $if_port_exitp -gt 0  ]
	then
    		echo "[Warning] : The $port already startup"
    		exit 1
	fi

	echo "Now,start redis$port ,please wait a minute..."

	$rediserver ${datadir}redis${port}.cnf

	if [ $? -ne 0 ]
	then
 		echo "[ERROR] : start redis$port  error: please check"
   		exit 1
	else
   		echo "start OK"
	fi
elif [ "$action" == 'stop' ];then
	if [ $port -gt 5999 ] && [ $port -lt 7000 ]
 	then
		if [ ! -d $datadir ]
		then
			echo "[Warning] : Not found $datadir,please check"
			exit 1
		fi
	else
  		echo "[ERROR] : $port is invalid,please check"
 		exit 2
	fi

	if_port_exitp=`netstat -g -lnp|grep :$port|wc -l`
        if_port_exit=`  ps -ef|grep redis-server|grep redis${port}.cnf|grep -v grep |wc -l  `
	if [ $if_port_exit -eq 0 ] && [ $if_port_exitp -eq 0 ]
	then
		echo "[Warning] : redis$port is not running"
		exit 1
	fi

	redisshutdown=`grep dbashutdown $datadir/redis${port}.cnf|grep -v '#'| wc -l`
	pass=`grep requirepass $datadir/redis${port}.cnf|egrep -v '#' |  awk '{print $2}'|wc -l`
	if [ $pass -eq 1 ]
	then
		password=`grep requirepass $datadir/redis${port}.cnf|egrep -v '#' |   awk '{print $2}'`
		if [ $redisshutdown == 1 ]
		then
			$rediscli -p $port -a $password  dbashutdown
		else
			$rediscli -p $port -a $password shutdown
		fi
	else
		if [ $redisshutdown == 1 ]
		then
			$rediscli -p $port dbashutdown	
		else
			$rediscli -p $port shutdown
		fi
	fi
	sleep 3
	pidcount=`ps -ef|grep redis-server|grep ":$port"|grep -v grep|wc -l`
	pidcount2=`ps -ef|grep redis-server|grep ${datadir}redis${port}.cnf |grep -v grep|wc -l`
	if [ $pidcount == 0 ] && [ $pidcount2 == 0 ] 
	then
		echo "redis$port stop ok "
	else
		echo "[ERROR] : redis$port stop failed,please check"
	fi
else
	echo "[ERROR] : $action is invalid,please check"
	exit 1
fi
