#!/bin/bash
### Author : dongjiashun
### Date : 2016-06-30
### Func : build primary-secondary relation
###

PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/mysql56/bin:/usr/local/mongodb30/bin:/usr/local/mongodb32/bin:/home/dba/bin:
export LANG=en_US.UTF-8


ADMINUSER=root
ADMINPASS="6198db5ce83c95c2"
MONITORUSER=mdmonitor
MONITORPASS="f8301db28007e2c2"




usage(){

        echo "Usage: bash $0 [OPTIONS]"
        echo "
              -p    port,between 7000 and 7999
              -s    all hosts of the replset,like ip1:port1,ip2:port2
              -u    BUSUSER,which equals to replsetname
              -d    BUSDB,default is equal to BUSUSER
	      -h    help info "
}


while getopts p:s:u:d:h OPTION
do
    case "$OPTION" in
       p) PORT=$OPTARG;;
       s) SERVERS=$OPTARG;;
       u) BUSUSER=$OPTARG;;
       d) BUSDB=$OPTARG;;
       h) usage;
          exit 1;;
	esac
done


if [ $# -eq 0 ]
then
	usage
	exit 1
fi

if [ -z $BUSDB ]
then
	BUSDB=$BUSUSER
fi

if [ $PORT -lt 7000 ] || [ $PORT -ge 8000 ]
then
	echo "[Warning] : $PORT is invalid,please check"
	exit 1
fi

###get the base directory

BDIR=/usr/local
MJDIR=/tmp

[ -f $MJDIR/mongo_json ] && mv -f  $MJDIR/mongo_json  $MJDIR/mongo_json.old 
mkdir -p $MJDIR/mongo_json


### e.g
### config_mongorep={_id:'mongorep',members:[{_id:0,host:'10.10.10.1:7001'}, {_id:1,host:'10.10.10.2:7001'}, {_id:2,host:'10.10.10.3:17001','arbiterOnly':'true'}] }
###
SET_CONFIGFILE(){


	i=0
	for host in `echo $SERVERS | sed  's#,#\n#g' `
	do
		i=`expr $i + 1`
		if [ AA"`echo $host|grep ':17'`" = AA ]
		then
			eval h${i}="{_id:$i,host:\'$host\'}"
		else
			eval h${i}="{_id:$i,host:\'$host\','arbiterOnly':'true'}"
		fi
	done
	itmp=`expr $i - 1`
	CONFIGF="config_$PORT={_id:'$BUSUSER',members:["
	for j in `seq 1 $itmp`
	do
		CONFIGF="${CONFIGF}$(eval echo \$h$j),"
	done
	CONFIGF="${CONFIGF}$(eval echo \$h$i)]}"

	echo $CONFIGF > $MJDIR/mongo_json/$PORT
	echo "rs.initiate(config_$PORT)" >> $MJDIR/mongo_json/$PORT
}

SET_CONFIGFILE

grep "DBA" $MJDIR/mongo_json/$PORT
if [ $? = 0 ]
then
	echo "[Warning] : old init file"
	exit 1
fi

FIND(){
for DATADIR in /data/ /data1/ /data2/ /data3/
do
        FILE=`find $DATADIR -name mongodb${PORT}.cnf 2>/dev/null`
        if [ AA"`echo $FILE | grep mongodb${PORT}.cnf`" != AA ]
        then
                DIR=`echo $FILE | sed  "s/mongodb${PORT}.cnf//g"`
                break
        fi
done

if [ "${DIR}" = "" ]
then
        echo "[ERROR] : There is no ${PORT} in ${HOSTNAME} "
        exit 1
fi
}

sleep 30
FIND

###get mongodb version
CNFILE=${DIR}mongodb${PORT}.cnf
if [ AA"`cat $CNFILE|grep 'mongo_version = mongodb32'`" != AA   ]
then
	MDVER=mongodb32
elif [ AA"`cat $CNFILE|grep 'mongo_version = mongodb26'`" != AA  ];then
	MDVER=mongodb26
elif [ AA"`cat $CNFILE|grep 'mongo_version = mongodb30'`" != AA  ];then
	MDVER=mongodb30
fi



ADD_USER(){

	### set password

	md5sum1=`echo $PORT|md5sum | awk '{print $1}'`
	PASS=`echo ${md5sum1}${PORT}|md5sum | awk '{print $1}'`
	PASS=`echo ${PASS:1:16}`

	#PASS=`openssl rand -base64 9`
	echo $PASS > ${DIR}.${PORT}


for i in {1..24}
do
	$BDIR/$MDVER/bin/mongo --port ${PORT} --eval 'printjson(db.isMaster())'|grep '"ismaster" : true' &>/dev/null
	if [ $? -eq  0 ]
	then
		OKGO=1
		break
	else
		sleep 5
		OKGO=0
	fi
done

if [ $MDVER = mongodb32  ] || [ $MDVER = mongodb30  ]
then
	$BDIR/$MDVER/bin/mongo admin --port ${PORT} --eval "db.createUser({user:'$ADMINUSER',pwd:'$ADMINPASS', roles:[{role:'root',db:'admin'}]})"
	$BDIR/$MDVER/bin/mongo admin -u$ADMINUSER -p$ADMINPASS --port ${PORT} --eval "db.createUser({user:'$MONITORUSER',pwd:'${MONITORPASS}', roles:[{role:'root',db:'admin'}]})"
	$BDIR/$MDVER/bin/mongo admin -u$ADMINUSER -p$ADMINPASS --port ${PORT}  --eval "printjson( db=db.getSiblingDB('${BUSDB}')) ;db.createUser({user:'$BUSUSER',pwd:'${PASS}', roles:[{role:'readWrite',db:'$BUSDB'} ] } )  ;"        

elif [ $MDVER = mongodb24  ];then
	$BDIR/$MDVER/bin/mongo admin --port ${PORT} --eval "db.addUser('$ADMINUSER','$ADMINPASS')"
	$BDIR/$MDVER/bin/mongo admin -u$ADMINUSER -p$ADMINPASS --port ${PORT} --eval "db.addUser('$MONITORUSER','${MONITORPASS}')"
	$BDIR/$MDVER/bin/mongo admin -u$ADMINUSER -p$ADMINPASS --port ${PORT} --eval "printjson(db=db.getSiblingDB('${BUSDB}'));db.addUser('$BUSUSER','${PASS}')"

else
	echo "TODO:mongodb30"
	exit 1

fi
}

echo "deploy  new repliSet:"
$BDIR/$MDVER/bin/mongo --port ${PORT} --quiet < $MJDIR/mongo_json/${PORT}
	
for i in {1..30}
do		
	$BDIR/$MDVER/bin/mongo --port ${PORT} --eval "printjson(rs.status())"|grep '"ok" : 0' &>/dev/null
	if [ $? -eq 1 ]
	then
		OKGO=1
		break
	else
		sleep 5
		OKGO=0
	fi
done
if [ ${OKGO} = 0 ]
then
	echo "[ERROR] : connect failed,please check"
	exit 1
else
	echo "[NOTE] : connect successfully"
	echo "DBA" > $MJDIR/mongo_json/${PORT}
	ADD_USER
fi
exit 0
