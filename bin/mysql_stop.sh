#!/bin/bash
#stop mysql for dongjiashun dba

PATH=$PATH:/home/dba/bin:/usr/local/mysql56/bin:/usr/local/mysql55/bin:/usr/local/mariadb102/bin
export LANG=en_US.UTF-8

function  usage()
{
	echo "usage:  sh  $0 -P port" 
}

if [[ "$#" -eq 0 ]]  
then
     usage
     exit 1
fi
while getopts P:h: OPTION
do
   case "$OPTION" in
       P)port=$OPTARG
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

host=127.0.0.1
password=xxxxxxx

if [ ! -z "`ps -ef|grep my${port}.cnf|grep /usr/local/mysql57|grep -v grep`" ];then
	mysql=/usr/local/mysql57
elif [ ! -z "`ps -ef|grep my${port}.cnf|grep /usr/local/mariadb102|grep -v grep`" ];then
	mysql=/usr/local/mariadb102
else
	mysql=/usr/local/mysql57
fi


if [ -d $mysql ]
then
    $mysql/bin/mysqladmin -u mstdba_mgr -p$password -h $host -P $port  shutdown
else
	echo "[Error]: Not found $mysql,please check"
	exit 1
fi

exit 0

