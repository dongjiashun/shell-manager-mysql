#!/bin/bash
### Author : hzdongjiashun
### Date : 2016-06-30
### Func : stop mongod
#

PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/mysql55/bin:/usr/local/mongodb30/bin:/usr/local/mongodb32/bin:/home/dba/bin


. /etc/profile

if [ "$1" != '-p' ]
then
        echo "eg:sh $0 -p PORT"
        exit 1
else
        if [ "$2" = "" ]
        then
                echo "eg:sh $0 -p PORT"
                exit 1
        fi
fi

PORT=$2
NUM=`echo ${PORT:0:1}`

if [ $((${NUM}+0)) = 1 ]
then
	KILLNUM=9
else
	KILLNUM=2
fi

MONGO_THREAD=`ps -ef|grep mongodb${PORT}|grep -v grep`
PIDFILE=`echo ${MONGO_THREAD}|awk '{print $2}'`
LOCKFILE=`echo ${MONGO_THREAD}|awk -F '-f' '{print $2}'|awk '{print $1}'|sed "s/mongodb${PORT}.cnf/mongod.lock/"`

if [ $((${PIDFILE}+0)) = 0 ]
then
	echo "mongoD not running"
else
	kill -${KILLNUM} ${PIDFILE} &>/dev/null
	if [ $((${KILLNUM}+0)) = 9 ]
	then
		rm -f ${LOCKFILE} > /dev/null
	fi

	sleep 2
	ps -ef|grep ${PIDFILE}|grep mongodb${PORT}.cnf|grep -v "grep" &>/dev/null
	if [ $? = 0 ]
	then
		kill -${KILLNUM} ${PIDFILE} &>/dev/null
		if [ $((${KILLNUM}+0)) = 9 ]
		then
			rm -f ${LOCKFILE} > /dev/null
		fi
	else
		if [ ${KILLNUM} = 2 ]
		then
			echo "mongo${PORT} PID:${PIDFILE} stoped ok by 'kill -2'"
		else
			echo "mongo${PORT} PID:${PIDFILE} stoped ok by 'kill -9'"
		fi
		exit 0
	fi

	sleep 5

	ps -ef|grep ${PIDFILE}|grep mongodb${PORT}.cnf|grep -v "grep" &>/dev/null
	if [ $? = 0 ]
	then
        	kill -9 ${PIDFILE} &>/dev/null
        	rm -f ${LOCKFILE} > /dev/null
        	echo "mongo${PORT} PID:${PIDFILE} stoped ok by 'kill -9'"
	else
        	echo "mongo${PORT} PID:${PIDFILE} stoped ok by 'kill -2'"
	fi

fi
