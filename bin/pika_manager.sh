#!/bin/bash
### Author : hzdongjiashun
### Date : 2015-05-22
### Func : start/stop pika


PATH=$PATH:/usr/local/redis30/bin:/usr/local/redis32/bin:/usr/local/mysql56/bin:/usr/local/pika23/bin
export LANG=en_US.UTF-8


BREDIS=/usr/local
pika23=$BREDIS/pika23/bin/pika
if [ ! -f $pika23 ]
then
	echo "[Warning] : Not found pika command,please check"
	exit 1
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

for DATADIR in  /data/ /data1/ /home/dba/ 
do
    FILE=`find $DATADIR -name pika${port}.cnf 2>/dev/null`
    if [ AA"`echo $FILE | grep pika${port}.cnf`" != AA ]
    then
        datadir=`echo $FILE | sed  "s/pika${port}.cnf//g"`
	if [ AA`cat $FILE | egrep 'pika_version=pika2.3'` != AA ]
	then
		version=pika23	
	fi
	pikaserver=/usr/local/$version/bin/pika
	pikacli=/usr/local/$version/bin/redis-cli
        break
    fi
done

if [ "$action" == 'start' ]
then
	if_port_exit=`  ps -ef| egrep 'bin/pika' |grep pika${port}.cnf|grep -v grep |wc -l  `
	if [ $if_port_exit -gt 0 ] 
	then
    		echo "[Warning] : The $port already startup"
    		exit 1
	fi

#	echo "Now,start pika$port ,please wait a minute..."

	$pikaserver -c ${datadir}pika${port}.cnf

	if [ $? -ne 0 ]
	then
 		echo "[ERROR] : start pika$port  error: please check"
   		exit 1
	else
   		echo "start pika$port OK"
	fi
elif [ "$action" == 'stop' ];then
	if [ $port -ge 9000 ] && [ $port -lt 10000 ]
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

        if_port_exit=`  ps -ef|egrep 'bin/pika' |grep pika${port}.cnf|grep -v grep |wc -l  `
	if [ $if_port_exit -eq 0 ] 
	then
		echo "[Warning] : pika$port is not running"
		exit 1
	fi

	pass=`grep requirepass $datadir/pika${port}.cnf|egrep -v '#' |  awk -F':' '{print $2}'|wc -l`
	if [ $pass -eq 1 ]
	then
		password=`grep requirepass $datadir/pika${port}.cnf|egrep -v '#' |   awk -F':'  '{print $2}'`
		$pikacli -p $port -a $password  shutdown
	fi
	sleep 5
	pidcount=`ps -ef|egrep 'bin/pika'  |grep ${datadir}pika${port}.cnf |grep -v grep|wc -l`
	if [ $pidcount == 0 ] 
	then
		echo "pika$port stop ok "
	else
		echo "[ERROR] : pika$port stop failed,please check"
	fi
else
	echo "[ERROR] : $action is invalid,please check"
	exit 1
fi
