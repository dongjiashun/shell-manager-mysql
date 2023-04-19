#!/bin/bash
### Author : dongjiashun
### Date : 2016-06-30
### Desc : restart arbitory after new mongod installation
### Exapmle : sh mongo_restart_arb.sh  -p 17991 
### exec this script only once


PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/mysql56/bin:/usr/local/mongodb30/bin:/usr/local/mongodb32/bin:
export LANG=en_US.utf8

PORT=$2

if [ "$1" != '-p' ]
then
        echo "[ERROR] : Option error"
        echo "e.g. bash $0 -p PORT"
        exit 1
else
        if [ "$2" = "" ]
        then
                echo "[ERROR] : Option error"
                echo "e.g. : bash $0  -p PORT"
                exit 1
        fi
fi

FIND(){
for DATADIR in /data1/ /data2/ /data3/
do
        FILE=`find ${DATADIR}mongodb${PORT} -name mongodb${PORT}.cnf 2>/dev/null`
        #FILE=`find $DATADIR -name mongodb${PORT}.cnf 2>/dev/null`
        if [ AA"`echo $FILE | grep mongodb${PORT}.cnf`" != AA ]
        then
                DIR=`echo $FILE | sed  "s/mongodb${PORT}.cnf//g"`
                break
        fi
done


if [ "${DIR}" = "" ]
then
        echo "[ERROR] : There is no $PORT in  ${HOSTNAME}"
        exit 1
fi
}

sleep 5

FIND
CNFILE=${DIR}mongodb${PORT}.cnf
if [ AA"`cat $CNFILE|grep 'mongo_version = mongodb32'`" != AA  ]
then
        MDVER=mongodb32
elif [ AA"`cat $CNFILE|grep 'mongo_version = mongodb30'`" != AA  ];then
	MDVER=mongodb30
else
	MDVER=mongodb32

fi

BDIR=/usr/local/bin
MBDIR=/usr/local

BIN="$MBDIR/$MDVER/bin/mongo    127.0.0.1:$PORT "



if [ $PORT -lt 10000 ] || [ $PORT -ge 20000 ]
then
	echo "[ERROR] : $PORT is invalid,please check"
	exit 1
fi

arb_restart() {
bash $BDIR/mongo_stop.sh -p ${PORT}
sleep 15 
ps -ef | grep ${MBDIR}/$MDVER/bin/mongod |grep mongodb${PORT}.cnf|grep -v grep &>/dev/null
if [ $? -eq 0 ]
then
	echo "[ERROR] : stop $PORT failed,please check!"
	exit 1
fi
bash  $BDIR/mongo_start.sh -p ${PORT}
sleep 15
ps -ef | grep  ${MBDIR}/$MDVER/bin/mongod   |grep mongodb${PORT}.cnf|grep -v grep &>/dev/null
if [ $? -ne 0 ]
then
        echo "[ERROR] : start $PORT failed,please check!"
        exit 1
fi
}

RESTARTFLAG=1
for i in {1..10}
do
	arb=`$BIN --eval "printjson(rs.status())"|grep ARBITER|awk -F: '{print $2}' |awk -F'"' '{print $2}'  2>/dev/null`
	if [ AA"$arb" = AA"ARBITER" ]
	then
	        arb_restart	
		RESTARTFLAG=0
		break
	else
		sleep 2
	fi
done

if [ $RESTARTFLAG -eq 1 ]
then
	echo "[ERROR] : mongodb$PORT is not ARBITER,please check!"
	exit 1
fi


