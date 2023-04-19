#!/bin/bash
### Author : dongjiashun
### Date : 2016-12-14
### Func : login redis at locahost to scan/del some key


export LANG=en_US.UTF-8
export PATH=$PATH:/usr/local/redis30/bin/:/usr/local/redis32/bin/:/usr/local/mysql56/bin

user='mstdba_mgr'
password="xxxxxxx"
admin_port=3873
admin_host='172.16.188.199'
admin_db=zabbix


usage(){
echo "option:
	-h redis master ip,default is 127.0.0.1
	-p redis port
	-a action less|cat|del|wc
	   default is less
	-k prekey
	   the prefix of keys
 "
echo "e.g. $0  -p 6901 -k abcdwww [ -a less ] "
exit 1
}



while getopts p:h:k:a: OPTION
do
   case "$OPTION" in
        p)PORT=${OPTARG}
        ;;
        h)HOST=${OPTARG}
        ;;
        k)prekey=${OPTARG}
        ;;
        a)action=${OPTARG}
        ;;
        *)
        usage
        ;;
   esac
done


if [ "${PORT}" = "" ] || [ -z $prekey ]
then
    usage
fi

if [ -z $action ]
then
	action="less"

fi


if [ "${PORT//[0-9,,]}" != "" ]
then
	echo "[usage] : $PORT is invalid"
	echo "please choose from 6000 to 6999"
	exit 1
fi


CONN(){
for DATADIR in  /data/ /data1/ /home/dba/
do
  if [ $PORT -gt 5999 ] && [ $PORT -lt 7000 ]
  then
    FILE=`find $DATADIR -name redis${PORT}.cnf 2>/dev/null`
    if [ AA"`echo $FILE | grep redis${PORT}.cnf`" != AA ]
    then
        datadir=`echo $FILE | sed  "s/redis${PORT}.cnf//g"`
	version=`cat $FILE |egrep redis_version|awk -F'=' '{print $2}'`
	REDIS=/usr/local/$version/bin/redis-cli
        break
    fi
  elif [ $PORT -gt 25999 ] && [ $PORT -lt 27000 ]
  then
    FILE=`find $DATADIR -name sentinel${PORT}.cnf 2>/dev/null`
    if [ AA"`echo $FILE | grep sentinel${PORT}.cnf`" != AA ]
    then
        datadir=`echo $FILE | sed  "s/sentinel${PORT}.cnf//g"`
        version=`cat $FILE |egrep redis_version|awk -F'=' '{print $2}'`
        REDIS=/usr/local/$version/bin/redis-cli
        break
    fi
  fi

done

if [ ! -f $REDIS ]
then
	echo "NO $REDIS,please check!"
	exit 1
fi

if [ $PORT  -lt 7000 ] && [ $PORT -ge 6000 ]
then
	pass=`cat $FILE |grep requirepass |grep -v '#' | awk '{print $2}' `
else
        pass=`cat $FILE  | grep 'sentinel auth-pass' |grep -v '#'| awk '{print $4}'`
fi

PASSWORD=$pass


if [ "${HOST}" = "" ]
then
    HOST='127.0.0.1'
fi

proc=`ps -ef|grep redis-server|grep -v grep | grep :${PORT} `
proc2=`ps -ef|grep redis-server|grep -v grep | grep ${PORT}.cnf `
if [ AA"$proc" = AA ] &&  [ AA"$proc2" = AA ] 
then
    echo "[Warning] : Not found ${PORT} on the server!"
    exit 1
else
	if [ AA$PASSWORD = AA ]
	then
	        REDISBIN="${REDIS} -h ${HOST} -p ${PORT}"
	else
		REDISBIN="${REDIS} -h ${HOST} -p ${PORT} -a ${PASSWORD}"
	fi
fi
}

CONN

### less cat 
function scan_key()
{
$REDISBIN  --scan --pattern  "${prekey}*" | $action

}

function wc_key()
{
$REDISBIN  --scan --pattern  "${prekey}*" | $action

}


function del_key()
{

echo "$REDISBIN  --scan --pattern  "${prekey}*" | xargs $REDISBIN del"
echo "after 1s,we will exec the cmd:"
sleep 1

$REDISBIN  --scan --pattern  "${prekey}*" | xargs $REDISBIN del


}

if [ "$action" = "del" ]
then
	del_key
elif [ "$action" = "less" ] || [ "$action" = "cat" ];then
	scan_key
elif [ ! -z   `echo "$action"|egrep wc` ] ;then
	action="wc -l "
	wc_key
else
	usage
fi


