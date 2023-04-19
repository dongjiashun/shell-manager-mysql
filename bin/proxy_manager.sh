#!/bin/bash
### Author : hzdongjiashun
### Date : 2015-05-22
### Func : start|stop|status mysql-proxy


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

datadir=/usr/local/mysql-proxy/

cd $datadir && sh ./bin/mysql-proxyd  $port $action




