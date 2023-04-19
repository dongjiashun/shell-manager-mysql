#!/bin/sh

### you can input the node_port manually or 
### the script get the node_port automatically


function usage()
{
echo "
usage: $0 [OPTION]
-p nodeport,rmq port
-a action
   value:start|stop|enable|disable|status
   start:start rabbitmq
   stop:stop rabbitmq
   status:rabbitmq status
   enable: enable rabbitmq_management
   disable:disable rabbitmq_management
   show:show the node_port & node_name
"
exit 1

}

while getopts p:h:n:a: OPTION
do
   case "$OPTION" in
       p)nodeport=$OPTARG
       ;;
       n)prehost=$OPTARG
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

if [ -z $nodeport ]
then
	usage
fi

function find_rmq()
{
basedir=none
for dir in /data/ /data1/ /data2/ /data3/
do
	if [ -d ${dir}rabbitmq$nodeport ]
	then	
		basedir=${dir}rabbitmq$nodeport
		break
	else
		continue
	fi
done
if [ $basedir == none ]
then
	echo "[ERROR]: no found  rabbitmq$port "
	exit 1
fi
}
find_rmq

if [ -z $prehost ]
then
	prehost=`hostname -s`
fi

#nodename=`hostname -s`_${nodeport}
nodename=${prehost}_${nodeport}

if [ -z "$nodename" ]
then
	echo "[ERROR]:please check node_name,exit 1"
	usage
fi

function show_rabbitmq()
{
	echo node_port:$nodeport
	echo node_name:$nodename
}

function start_rabbitmq()
{
	cd $basedir &&   RABBITMQ_NODE_PORT=$nodeport  RABBITMQ_NODENAME=$nodename   ./sbin/rabbitmq-server  -detached

}

function stop_rabbitmq()
{
	cd $basedir &&  ./sbin/rabbitmqctl -n $nodename  stop
}

function status_rabbitmq()
{
        cd $basedir && ./sbin/rabbitmqctl -n $nodename  status
}

function enable_monitor()
{
	cd $basedir &&  ./sbin/rabbitmq-plugins -n $nodename  enable rabbitmq_management
}

function disable_monitor()
{
        cd $basedir &&  ./sbin/rabbitmq-plugins -n $nodename  disable rabbitmq_management

}

if [ -z $action ]
then
	echo "[ERROR]:invalid action,please check"
	usage
fi


ps -ef|egrep "/usr/lib64/erlang/erts-6.3/bin/epmd -daemon" |grep -v grep >/dev/null 2>&1
if [ $? -ne 0 ]
then
	/usr/lib64/erlang/erts-6.3/bin/epmd -daemon
fi

if [ $action = status ]
then
	status_rabbitmq
elif [ $action = start ];then
	cd $basedir &&  ./sbin/rabbitmqctl -n $nodename status  >/dev/null 2>&1
	if [ $? -ne 0 ]
	then
		start_rabbitmq
	else
		echo "[info]: ${nodename}:${nodeport}  already startup"
	fi
elif [ $action = stop ];then
	stop_rabbitmq
elif [ $action = enable ];then
	netstat -anltp|egrep 1$nodeport  >/dev/null 2>&1
	if [ $? -ne 0 ]
	then
		enable_monitor
	else
		echo "[info]: rabbitmq_management is already enabled"
	fi
elif [ $action = disable ];then
	disable_monitor
elif [ $action = show ];then
	show_rabbitmq
else
	echo "[ERROR]:invalid action,please check,exit 1"
	usage
fi

exit 0

