#!/bin/bash
### author : dongjs
### date : 2016-06-14
### func : login mysql at localhost

PATH=$PATH:/usr/local/bin:/usr/local/mysql56/bin
export LANG=en_US.UTF-8

function  usage()
{
	echo "fail"
	echo "usage:    $0 -p port -m master_ip [ -H ip ]"
	echo "e.g. $0 -p 3001 -m 10.11.12.14"
}

if [[ "$#" -lt 1 ]]  
then
     usage
     exit 1
fi

###default directory
user=mstdba_mgr
password=xxxxxxx



while getopts p:H:m: OPTION
do
   case "$OPTION" in
       p)port=$OPTARG;;
       H)host=$OPTARG;;
       m)master_ip=$OPTARG;;
       *)usage      
         exit 1
       ;;
   esac
done

function findatadir()
{
for d in /data/ /data2/ /home/dba/
do
        FILE=`find $d/mysql$port  -name my${port}.cnf 2>/dev/null`
        if [ ! -z $FILE  ]
        then
                datadir=$d
		version=`cat $FILE|egrep 'mysql_version=mysql57'`
		if [ -z $version ]
		then
			MBIN=/usr/local/mysql57/bin
		else
                        MBIN=/usr/local/mysql57/bin
		fi
                break
        fi

done
        if [ -z $FILE ]
        then
                echo "[fail]:No $port found,please check!"
                exit 1
        fi
}


findatadir

if [ -d $MBIN ]
then
        mysql=$MBIN
else
        echo "[fail]: no mysql binary,please check!"
        exit 1
fi

if [ -z $host ]
then
	host=127.0.0.1
fi

binlog_file=${port}-binlog.000001
binlog_pos=120


is_gitd=`$mysql/mysql  -A -u $user -p$password  -h $host -P $port -e "select @@gtid_mode;"|sed 1d`

if [ $is_gitd == "OFF" ] || [ $is_gitd == "off" ] 
then
	replsql="change master to master_host=\"$master_ip\", master_user='mreplic', master_password='699c6929cc14680c',master_port=$port,master_log_file=\"$binlog_file\",master_log_pos=$binlog_pos ;"
else
	replsql="change master to master_host=\"$master_ip\", master_user='mreplic', master_password='699c6929cc14680c',master_port=$port, master_auto_position = 1;"

fi

$mysql/mysql  -A -u $user -p$password  -h $host -P $port -e "$replsql"
if [ $? -eq 0 ]
then
        echo "change ok"
        
else
        echo "change fail"
        exit 1
fi

$mysql/mysql  -A -u $user -p$password  -h $host -P $port -e "start slave"
if [ $? -eq 0 ]
then
	echo "slaveof ok"
	exit 0
else
        echo "slaveof fail"
        exit 1
fi

