#!/bin/bash
### Author : hzdongjiashun
### Date : 2015-05-22
### Func : start redis or stop redis


function  usage()
{
	echo "usage: $0  OPTION" 
	echo "	OPTION:"
	echo "	-p port,zk port"
	echo "	-a sction,valid is top|start|status|restart" 
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

FILE=none
for DATADIR in  /data/ /data1/ /data2/ /data3/
do
    if [ ! -d ${DATADIR}zookeeper$port/conf ] 
    then
	continue
    fi
     FILE=`find ${DATADIR}zookeeper$port/conf/  -name zk${port}.cfg 2>/dev/null`
    if [ AA"`echo $FILE | grep zk${port}.cfg`" != AA ]
    then
        datadir=${DATADIR}zookeeper$port  
        break
    fi
done

if [ $FILE == none ]
then
	echo "[ERROR]: no zk$port found,exit..."
	exit 1
fi

cd $datadir && sh ./bin/zkServer.sh $action


