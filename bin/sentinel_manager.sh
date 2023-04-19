#!/bin/bash
### author : dongjiashun
### date : 2015-08-13
### func : start or stop sentinel,support 2.8
### update 2016-08-08
### support 3.x

export LANG=en_US.UTF-8 
export PATH=$PATH:/usr/local/redis30/bin/:/usr/local/mysql56/bin:/usr/local/redis31/bin:/usr/local/redis32/bin:

function  Usage(){
	echo "Usage: sh $0 -p port -a action
	             -a :start|stop" 
	echo "sh $0 -p 26901 -a start"
	echo "sh $0 -p 26901 -a stop"
}

if [ $# -ne 4 ];then
	Usage
	exit 1
fi


while getopts p:a:h: OPTION
do
	case "$OPTION" in
       		p)
			port=$OPTARG
       			;;
       		a)
			action=$OPTARG
       			;;
       		h)
			Usage
         		exit 0
       			;;
       		*)
        		Usage
            		exit 1
          		;;
   	esac
done

if [ -z $port ];then
	Usage
	exit 1
fi

if [ $port -lt 26000 -o $port -gt 27000 ]
then
	echo "$port is invalid,please check!"
	exit 1
fi

if [ -z $action ];then
        Usage
        exit 1
fi

FIND(){
for DATADIR in /data/ /data1/  /data2/
do
    confFile=`find $DATADIR -name sentinel${port}.cnf 2>/dev/null`
    if [ AA"`echo $confFile | grep sentinel${port}.cnf`" != AA ]
    then
        dataDir=`echo $confFile | sed  "s/sentinel${port}.cnf//g"`
        version=`cat $confFile |egrep redis_version|awk -F'=' '{print $2}'`
        redisServer=/usr/local/$version/bin/redis-server
        break
    fi
done
}

FIND

portExists=`  ps -ef| grep redis-server|egrep "sentinel${port}.cnf|:$port" |grep -v grep|wc -l`

if [ "$action" == "stop" ];then
	if [ $portExists -eq 1 ] 
	then
		curPID=` ps -ef|grep redis-server|egrep "sentinel${port}.cnf|:$port" |grep -v grep |awk '{print $2}'`
		sentinelPPID=`cat /proc/"$curPID"/status 2>/dev/null | grep PPid | awk '{print $2}'`
		if [ $sentinelPPID -eq 1 ];then
			kill $curPID 2>/dev/null
			sleep 3 
	                curPID=` ps -ef|grep redis-server|egrep "sentinel${port}.cnf|:$port" |grep -v grep |awk '{print $2}'`
			if [ -z $curPID ] 
			then
				echo "stop sentinel $port ok!"
				exit 0
			else
				echo "stop sentinel $port failed!"	
				exit 1
			fi
		else
			echo "Sentinle Parent ID is not 1,break and exit!" 
			exit 1
		fi
	elif [ $portExists -eq 0 ] 
	then
		echo "No Found Port Running!"
		exit 1
	else
		echo "Port Error!"
		exit 1 
	fi
	
elif [ "$action" == "start" ];then
	if [ $portExists -gt 0 ]  
	then
		echo "Port already in use,Please Check!"
		exit 1
	else
		echo "start sentinel$port ..."	
	fi
else
	Usage
	exit 1
fi

logFile="${dataDir}sentinel$port.log"

if [ ! -f $confFile ];then
	echo "Can't find conf file,Please Check!"
	exit 1
fi

if [ ! -f $logFile ];then
	touch $logFile
fi

 $redisServer $confFile --sentinel >> $logFile 2>&1 
sleep 2
curPID=` ps -ef|grep redis-server|egrep  "sentinel${port}.cnf|:$port" |grep -v grep |awk '{print $2}'`
if [ ! -z $curPID ];then
	echo "start success!"
else
	echo "start error!!"
	exit 1
fi

exit 0


