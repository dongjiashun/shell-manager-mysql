#!/bin/sh

### you can input the node_port manually or 
### the script get the node_port automatically


function usage()
{
echo "
usage: $0 [OPTION]
-p port,kfk port
-a action
   value:start|stop|status
   start:start rabbitmq
   stop:stop rabbitmq
   status:rabbitmq status
"
exit 1

}

while getopts p:h:a: OPTION
do
   case "$OPTION" in
       p)port=$OPTARG
       ;;
       h)usage
         exit 1
       ;;
       a)action=$OPTARG
       ;;
       *)usage
         exit 1
       ;;
   esac
done

if [ -z $port ]
then
	usage
fi

function find_kfk()
{
basedir=none
for dir in /data/ /data1/ /data2/ /data3/
do
	if [ -d ${dir}kafka$port ]
	then	
		basedir=${dir}kafka$port
		break
	else
		continue
	fi
done
if [ $basedir == none ]
then
	echo "[ERROR]: no found  kafka$port "
	exit 1
fi
}
find_kfk

function start_kfk()
{
        ps -ef|egrep $basedir |grep java|grep -v grep >/dev/null
	if [ $? -ne 0 ]
	then
		cd $basedir &&  ./bin/kafka-server-start.sh  -daemon ./config/server.properties   
		sleep 1
	        ps -ef|egrep $basedir |grep java |grep -v grep  >/dev/null
		if [ $? -eq 0 ]
		then
			echo "[info]: start kafka$port ok"
		else
                        echo "[error]: start kafka$port failed,please check!"
		fi
	else
		echo "[WARN]: kafka$port already startup"
	fi

}

function stop_kfk()
{
	cd $basedir &&  ./bin/kafka-server-stop.sh 
}

function status_kfk()
{
        ps -ef|egrep $basedir |grep -v grep 
	if [ $? -ne 0 ]
	then
		echo "[WARN]: no kafka$port found,please check!"
	fi
}


if [ -z $action ]
then
	echo "[ERROR]:invalid action,please check"
	usage
fi

if [ $action = status ]
then
	status_kfk
elif [ $action = start ];then
	start_kfk
elif [ $action = stop ];then
	stop_kfk
else
	echo "[ERROR]:invalid action,please check,exit 1"
	usage
fi

exit 0

