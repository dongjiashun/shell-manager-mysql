#!/bin/bash
### Author : dongjiashun
### Date : 2016-06-30
### Func : start mongod,arb with version >=mongodb3.0
### and not support mongodb 2.x
### TODO: support mongoS

PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/mysql56/bin:/usr/local/mongodb30/bin:/usr/local/mongodb32/bin:/home/dba/bin:

#. /etc/profile
export LANG=en_US.UTF-8


if [ "$1" != "-p" ]
then
	echo "e.g. : bash $0 -p PORT"
	exit 1
else
	if [ "$2" = "" ]
	then
        	echo "e.g. : bash $0 -p PORT"
        	exit 1
	fi
fi

MBDIR=/usr/local
BDIR=/usr/local/bin

PORT=$2
NUM=`echo ${PORT:0:1}`

ADMINUSER=root
ADMINPASS="6198db5ce83c95c2"
MONITORUSER=mdmonitor
MONITORPASS="f8301db28007e2c2"



BUSUSER=mongo

FIND(){
for DATADIR in /data/ /data1/  /data2/ /data3/
do
	FILE=`find ${DATADIR}mongodb$PORT  -name mongodb${PORT}.cnf 2>/dev/null`
	#FILE=`find $DATADIR -name mongodb${PORT}.cnf 2>/dev/null`
	if [ AA"`echo $FILE | grep mongodb${PORT}.cnf`" != AA ]
	then
		DIR=`echo $FILE | sed  "s/mongodb${PORT}.cnf//g"`
		break
	fi
done
if [ "${DIR}" = "" ]
then
	echo "[ERROR] : There is no ${PORT}  in  ${HOSTNAME} "
	exit 1
fi
}

REMOVE_LOCK(){
if [ -f "${DIR}mongod.lock" ]
then
	rm  -rf ${DIR}mongod.lock
fi
}

ARB_SEC_CHECK(){
	SEC=2
	AUTH="--authenticationDatabase admin -u $ADMINUSER -p $ADMINPASS"
	$MBDIR/$MDVER/bin/mongo ${AUTH} --port ${PORT} --eval "db.isMaster()" &>/dev/null

	if [ $? -ne 0 ]
	then

		sleep 5
		$MBDIR/$MDVER/bin/mongo --host 127.0.0.1  --port ${PORT} --eval 'printjson(db.isMaster())' | grep -i 'arbiterOnly'|grep -i 'true'  &>/dev/null
		if [ $? -eq 0 ]
		then
			### 1:arb
			SEC=1
		else
			SEC=0
		fi
	fi
}

### arb node adds user auth
ARB_SEC_ADD(){
	ARB_SEC_CHECK
	if [ ${SEC} = 1 ]
	then
		cat ${DIR}mongodb${PORT}.cnf|grep -v "\#" | grep "keyFile" &>/dev/null
		if [ $? -eq 0 ]
		then
			bash $BDIR/mongo_stop.sh -p ${PORT}

			if [ AA"`cat $CNFILE |grep 'mongo_version = mongodb3'`" != AA ] 
			then
                                sed -i 's/replication/#replication/g' ${DIR}mongodb${PORT}.cnf
                                sed -i 's/oplogSizeMB/#oplogSizeMB/g' ${DIR}mongodb${PORT}.cnf
                                sed -i 's/replSetName/#replSetName/g' ${DIR}mongodb${PORT}.cnf

			else 
                                sed -i 's/replication/#replication/g' ${DIR}mongodb${PORT}.cnf
                                sed -i 's/oplogSizeMB/#oplogSizeMB/g' ${DIR}mongodb${PORT}.cnf
                                sed -i 's/replSetName/#replSetName/g' ${DIR}mongodb${PORT}.cnf
			fi
			$MBDIR/$MDVER/bin/mongod -f ${DIR}mongodb${PORT}.cnf
			sleep 5
			if [ $MDVER = mongodb32  ] ||  [ $MDVER = mongodb30  ] 
			then
				$MBDIR/$MDVER/bin/mongo admin --port ${PORT} --eval "db.createUser({user: \"$ADMINUSER\",pwd: \"$ADMINPASS\", roles:[{role:'root',db:'admin'}]})" &>/dev/null
				if [ $? -ne 0 ]
				then
					echo "add root user failed,please check!"
					exit 1
				fi

				sleep 3 
				$MBDIR/$MDVER/bin/mongo --authenticationDatabase  admin -u$ADMINUSER -p$ADMINPASS  --port ${PORT} --eval "db.fsyncLock() " 
				sleep 2
				$MBDIR/$MDVER/bin/mongo --authenticationDatabase  admin -u$ADMINUSER -p$ADMINPASS  --port ${PORT} --eval "db.fsyncUnlock()" 

			fi

			bash $BDIR/mongo_stop.sh -p ${PORT}
                        if [ AA"`cat $CNFILE |grep 'mongo_version = mongodb3'`" != AA ] 
                        then
                                sed -i 's/#replication/replication/g' ${DIR}mongodb${PORT}.cnf
                                sed -i 's/#oplogSizeMB/oplogSizeMB/g' ${DIR}mongodb${PORT}.cnf
                                sed -i 's/#replSetName/replSetName/g' ${DIR}mongodb${PORT}.cnf

			else
                                sed -i 's/#replication/replication/g' ${DIR}mongodb${PORT}.cnf
                                sed -i 's/#oplogSizeMB/oplogSizeMB/g' ${DIR}mongodb${PORT}.cnf
                                sed -i 's/#replSetName/replSetName/g' ${DIR}mongodb${PORT}.cnf

                        fi


			numactl --interleave=all $MBDIR/$MDVER/bin/mongod -f ${DIR}mongodb${PORT}.cnf &>/dev/null
			if [ $? -ne 0 ]
			then
		             	$MBDIR/$MDVER/bin/mongod -f ${DIR}mongodb${PORT}.cnf &>/dev/null
			fi
		fi
	fi
}

###main 
#ps -ef|grep mongodb${PORT}.cnf|grep -v grep
ps -ef|grep /usr/local/$MDVER |grep  mongodb${PORT}.cnf|grep -v grep
if [ $? -eq 0 ]
then
	echo "[WARNING] : mongodb${PORT} has been started"
	exit 1
fi
sleep 5

FIND
CNFILE=${DIR}mongodb${PORT}.cnf

### set mongodb version
if [ AA"`cat $CNFILE|grep 'mongo_version = mongodb32'`" != AA  ]
then
	MDVER=mongodb32
elif [ AA"`cat $CNFILE|grep 'mongo_version = mongodb30'`" != AA  ];then
	MDVER=mongodb30
else
        MDVER=mongodb32
fi



if [ "${DIR}" = '' ]
then
	echo "[ERROR] : PORT ERROR,please check"
	exit 1
fi

###mongos node,we will support this later
### TODO
if [ ${NUM} = "3" ]
then
	REMOVE_LOCK
	numactl --interleave=all $MBDIR/$MDVER/bin/mongos -f ${DIR}mongodb${PORT}.cnf &>/dev/null
	if [ $? -ne 0 ]
	then
		REMOVE_LOCK
		$MBDIR/$MDVER/bin/mongos -f ${DIR}mongodb${PORT}.cnf &>/dev/null
		
		sleep 5
		if [ $? -eq 0 ]
		then
			echo "mongos $PORT   startup ok without NUMA"
			$MBDIR/$MDVER/bin/mongo 127.0.0.1:$PORT/admin -u$ADMINUSER  -p$ADMINPASS --quiet   --eval "quit;"
	        if [ $? -ne 0 ]
	        then
        	        echo "$PORT startup at the first time."
			md5sum1=`echo $PORT|md5sum | awk '{print $1}'`
			PASS=`echo ${md5sum1}${PORT}|md5sum | awk '{print $1}'`
			PASS=`echo ${PASS:1:16}`

			#PASS=`openssl rand -base64 9`
			echo $PASS > ${DIR}.$PORT

			if [ $MDVER = mongodb26  ] || [ $MDVER = mongodb30  ]
        	        then
				$MBDIR/$MDVER/bin/mongo admin --port ${PORT} --eval "db.createUser({user:\"$ADMINUSER\",pwd:\"$ADMINPASS\", roles:[{role:'root',db:'admin'}]})" &>/dev/null
				$MBDIR/$MDVER/bin/mongo admin -u $ADMINUSER -p $ADMINPASS --port ${PORT} --eval "db.createUser({user:\"$MONITORUSER\",pwd:'${MONITORPASS}', roles:[{role:'root',db:'admin'}]})" &>/dev/null
				$MBDIR/$MDVER/bin/mongo admin -u $ADMINUSER -p $ADMINPASS --port ${PORT} --eval "db.createUser({user:\"$BUSUSER\",pwd:'${PASS}', roles:[{role:'root',db:'admin'}]})" &>/dev/null
        		elif [  $MDVER = mongodb24 ];then
				$MBDIR/$MDVER/bin/mongo admin --port ${PORT} --eval "db.addUser(\"$ADMINUSER\",\"$ADMINPASS\")" &>/dev/null
				$MBDIR/$MDVER/bin/mongo admin -u $ADMINUSER -p $ADMINPASS --port ${PORT} --eval "db.addUser('$MONITORUSER','${MONITORPASS}')"
				$MBDIR/$MDVER/bin/mongo admin -u $ADMINUSER -p $ADMINPASS --port ${PORT} --eval "db.addUser('$BUSUSER','${PASS}')"
	
			fi
	        fi
		else
			echo "[ERROR] : mongos $PORT startup failed"
			exit 1
		fi
	else
		sleep 5
		ps -ef|grep mongodb${PORT}.cnf &>/dev/null
		if [ $? -eq 0 ]
		then
			echo "[NOTE] : mongos $PORT startup ok with NUMA"
			$MBDIR/$MDVER/bin/mongo 127.0.0.1:$PORT/admin -u$ADMINUSER -p$ADMINPASS --quiet   --eval "quit;"
			if [ $? -ne 0 ]
			then
				echo "[NOTE] : $PORT startup at the first time."
	                        md5sum1=`echo $PORT|md5sum | awk '{print $1}'`
        	                PASS=`echo ${md5sum1}${PORT}|md5sum | awk '{print $1}'`
                	        PASS=`echo ${PASS:1:16}`

		                #PASS=`openssl rand -base64 9`
				echo $PASS > ${DIR}.$PORT
				if [ $MDVER = mongodb26  ] || [ $MDVER = mongodb30  ]
				then
					$MBDIR/$MDVER/bin/mongo admin --port ${PORT} --eval "db.createUser({user:'$ADMINUSER',pwd:'$ADMINPASS', roles:[{role:'root',db:'admin'}]})" &>/dev/null
					$MBDIR/$MDVER/bin/mongo admin -u$ADMINUSER -p$ADMINPASS --port ${PORT} --eval "db.createUser({user:'$MONITORUSER',pwd:'${MONITORPASS}', roles:[{role:'root',db:'admin'}]})" &>/dev/null
					$MBDIR/$MDVER/bin/mongo admin -u$ADMINUSER -p$ADMINPASS --port ${PORT} --eval "db.createUser({user:'$BUSUSER',pwd:'${PASS}', roles:[{role:'root',db:'admin'}]})" &>/dev/null
				elif [ $MDVER = mongodb24  ];then
					$MBDIR/$MDVER/bin/mongo admin --port ${PORT} --eval "db.addUser('monitor','62068042172418e8')" &>/dev/null
					$MBDIR/$MDVER/bin/mongo admin -u$ADMINUSER -p$ADMINPASS --port ${PORT} --eval "db.addUser('$MONITORUSER','${MONITORPASS}')"
					$MBDIR/$MDVER/bin/mongo admin -u$ADMINUSER -p$ADMINPASS --port ${PORT} --eval "db.addUser('$BUSUSER','${PASS}')"
				fi
			fi
		else
			echo "[ERROR] : mongos $PORT startup failed"
			exit 1
		fi
	fi

else	
	REMOVE_LOCK
	numactl --interleave=all $MBDIR/$MDVER/bin/mongod -f ${DIR}mongodb${PORT}.cnf &>/dev/null
	if [ $? -ne 0 ]
	then
		REMOVE_LOCK
		$MBDIR/$MDVER/bin/mongod -f ${DIR}mongodb${PORT}.cnf &>/dev/null
		if [ $? -eq 0 ]
		then
			if [ ${NUM} = "1" ]
			then
				ARB_SEC_ADD
			fi
			echo "[NOTE] : mongod $PORT startup ok without NUMA"
		else
			echo "[ERROR] : mongod $PORT startup failed"
			exit 1
		fi
	else
		ps -ef|grep mongodb${PORT}.cnf &>/dev/null
		if [ $? -eq 0 ]
		then
			if [ ${NUM} = "1" ]
			then
				ARB_SEC_ADD
			fi
			echo "[NOTE] : mongod $PORT startup ok with NUMA"
		else
			echo "[ERROR] : mongod $PORT  startup failed"
			exit 1
		fi

	fi
fi
exit 0
