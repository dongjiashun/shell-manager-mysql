#!/bin/bash
#start mysql for dongjiashun dba


PATH=$PATH:/home/dba/bin:/usr/local/mysql56/bin:/usr/local/mysql55/bin:/usr/local/mariadb102/bin
export LANG=en_US.UTF-8


function  usage()
{
	echo "usage:  sh  $0 -P port" 
}

if [[ "$#" -ne 2 ]]  
then
     usage
     exit 1
fi
password=xxxxxxx

function findatadir()
{
for d in /data/ /data2/ /data3/
do
	FILE=`find $d/mysql$port  -name my${port}.cnf 2>/dev/null`
	if [ ! -z $FILE  ]
	then
		datadir=$d
		break
	fi

done
	if [ -z $FILE ]
	then
		echo "No $port found,please check!"
		exit 1
	fi
}


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
findatadir

#port_exist=`netstat -an|grep LISTEN|grep tcp|grep $port|wc -l`
#port_exist=`netstat -an|grep LISTEN|grep tcp|grep :$port|wc -l`
#if [ $port_exist -ne 0 ]
#then
#        echo "$port exist"
#        exit 1
#fi

version=`cat $datadir/mysql$port/my${port}.cnf|grep mysql_version|awk -F'=' '{print $2}'`
if [ $version = mysql57 ]
then  
	mysql=/usr/local/mysql57
elif [ $version = mysql56 ];then  
	mysql=/usr/local/mysql56
elif [ $version = mariadb102 ];then
        mysql=/usr/local/mariadb102
fi

if [ -d $mysql ]
then 
	echo "start mysql,waiting..."
	cd $mysql
	#/usr/bin/numactl --interleave=all ./bin/mysqld_safe --defaults-file=$datadir/mysql$port/my${port}.cnf >/dev/null 2>&1 &
	./bin/mysqld_safe --defaults-file=$datadir/mysql$port/my${port}.cnf >/dev/null 2>&1 &
else
   echo "Not found $mysqlstart error"
   echo "you must have $mysql directory"
   exit 1
fi
if [  -d $datadir/mysql$port/test ]
then
	new_init=0
else
        new_init=1
fi
echo '------------------------------'$new_init
if [ $new_init -eq 1 ]
then
		sleep 20
		port_exist=`netstat -an|grep LISTEN|grep tcp|grep $port|wc -l`
		if [ $port_exist -eq 0 ]
		then
			sleep 60
		fi
		socket=`ls /tmp/mysql$port\.sock|wc -l`
		if [ $socket -eq 0 ]
	        then
	                sleep 60	
        	fi
		host="`echo $HOSTNAME`"
		passwordinit=`cat $datadir/mysql$port/${port}-error.log | grep 'root@localhost:' | awk -F'root@localhost: ' '{print $2}'`
                echo --------------$passwordinit
		$mysql/bin/mysql -S /tmp/mysql${port}.sock -uroot -p$passwordinit --connect-expired-password < /usr/local/bin/grantinit.sql
		$mysql/bin/mysql -S /tmp/mysql${port}.sock -uroot -pxxxxxxx -e 'reset master'		
fi



