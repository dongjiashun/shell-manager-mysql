#!/bin/bash
### Author : dongjiashun
### Date : 2016-06-30
### Func : init mongodb,including mdm,mds,mda,not support msc,mss now
###

PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/mysql56/bin:/usr/local/mongodb30/bin:/usr/local/mongodb32/bin:/usr/local/mongodb36/bin:
export LANG=en_US.utf8


usage() {
	
		echo "Usage: bash $0 [OPTIONS]"
		echo "
			  -p	port,between 7000 and 7999
			  -d	the direcotry of mongodb<port>
			  -r	role,one of mdm,mds,mda,msc,mss
		  		mdm:primary,mds:secondary,mda:arbitory,msc:configsvr,mss:mongos
			  -s	the size of oplog,
		  		unit:GB
			  -w    the size about CACHESIZE of WT
			  -v	version of the mongodb,
		  		value:
				mongodb36,mongodb32,mongodb30
				default value:mongodb36
			  -c	the configsvr host, Optional 
		  		value:
				ip1:port,ip2:port,ip3:port
			  -R	ReplSet name	
			  -h	help info

			e.g:
			bash $0 -p 7999 -d /data1 -r mdm -s 10 -w 2 [ -v mongodb36 ] -R test7992
			bash $0 -p 7999 -d /data1 -r mds -s 10 -w 2  [ -v mongodb36 ] -R test7992
			bash $0 -p 7999 -d /data1 -r mda -s 10 -w 2  [ -v mongodb36 ] -R test7992
			bash $0 -p 7999 -d /data1 -r msc -s 10 -w 2  [ -v mongodb36 ]
			baAfter init of all msc,you can:
			bash $0 -p 7999 -d /data1 -r mss -s 10  -w 2 [ -v mongodb36 ] -c ip1:port,ip2:port,ip3:port	

		"
		exit 1
}



while getopts p:d:r:R:s:w:j:v:c:h OPTION
do
	case "$OPTION" in
		p) PORT=$OPTARG;;
		d) DIR=$OPTARG;;
		r) ROLE=$OPTARG;;
		R) REPLSET=$OPTARG;;
		s) OPSIZE=$OPTARG;;
		w) CACHESIZE=$OPTARG;;
		v) VER=$OPTARG;;
		c) COFFIGDB=$OPTARG;
		   MSSCONFIGDB="configdb = $COFFIGDB";;
		h) usage;
		   exit 1;;
	esac
done

																																						  
if [ $# -eq 0 ]
then
	usage
	exit 1
fi

HPORT=`echo ${PORT:0:1}`
if [ "${HPORT}" = "1" ] || [ "${HPORT}" = "2" ] || [ "${HPORT}" = "3" ]
then
	PORT=`echo ${PORT:1:4}`
fi

if [ $PORT -lt 7000 ] || [ $PORT -ge 8000 ]
then
	echo "[ERROR] : $PORT is invalid,please check!"
	exit 1
fi


if [ "${VER}" = '' ]
then
	MONGOVER=mongodb36
else
	MONGOVER="${VER}"
fi




case ${ROLE} in
	mdm)
	RPORT="${PORT}";;
	mds)
	RPORT="${PORT}";;
	mda)
	RPORT="1${PORT}";;
	msc)
	RPORT="2${PORT}";;
	mss)
	RPORT="3${PORT}";;
	*)
	echo "role error"
	exit 1;;
esac

for DATADIR in /data1/ /data2/ /data3/ /data/
do
	FILE=`find ${DATADIR}mongodb$RPORT -name mongodb${RPORT}.cnf 2>/dev/null`
	if [ AA"`echo $FILE | grep mongodb$BPORT`" != AA ]
        then
			echo "[Warning] : duplicate port,please check"
			exit 1
	fi
done


if [ ! -e ${DIR}/mongodb${RPORT} ]
then
	mkdir -p ${DIR}/mongodb${RPORT}/log
	echo 'd8d0d3d83a7164673f8b363ed2284ba3' > ${DIR}/mongodb${RPORT}/keyFile
	chmod 600 ${DIR}/mongodb${RPORT}/keyFile
else
	echo "[ERROR] : ${DIR}/mongodb${RPORT} has exist,please check"
	exit 1
fi

###default:journal=true
JOUR='journal'

if [ $OPSIZE -gt 0 ]
then
	OPSIZE=`echo $OPSIZE*1024|bc`
else
	OPSIZE=5120
fi

if [ -z $OPSIZE ]
then
	OPSIZE=10
fi

if [ -z $CACHESIZE ]
then
	CACHESIZE=1
fi



###init mongodb3.0+
if [ AA"`echo ${MONGOVER} | grep mongodb3`" != AA ]
then
cat > ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf << EOF
systemLog:
 destination: file
 path: ${DIR}/mongodb${RPORT}/log/mongod.log
 logAppend: true
 logRotate: reopen
operationProfiling:
 mode: slowOp
 slowOpThresholdMs: 100
storage:
 journal:
  enabled: true
 dbPath: ${DIR}/mongodb${RPORT}
 directoryPerDB: true
 engine: wiredTiger
 wiredTiger:
  engineConfig:
   cacheSizeGB: $CACHESIZE
   directoryForIndexes: true
  collectionConfig:
   blockCompressor: snappy
  indexConfig:
   prefixCompression: false
net:
 port: ${RPORT}
 maxIncomingConnections: 20000
 #bindIp: 0.0.0.0
replication:
 oplogSizeMB: ${OPSIZE}
 replSetName: $REPLSET
#sharding:
# clusterRole: configsvr
processManagement:
 fork: true
 pidFilePath: ${DIR}/mongodb${RPORT}/mongod.pid
security:
 keyFile: ${DIR}/mongodb${RPORT}/keyFile
 authorization: enabled
###version
#mongo_version = ${MONGOVER}
EOF

fi

if [ AA"`echo ${MONGOVER} | grep mongodb36`" != AA ]
then
	sed -i 's/#bind/bind/g'  ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf

fi

###mongodb3.0+ for mongoS
if [ AA"`echo ${VER} | grep mongodb3`" != AA ]
then
	if [ "${ROLE}" = "msc" ]
	then

                sed -i 's/#sharding:/sharding:/' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
                sed -i 's/# clusterRole: configsvr/ clusterRole: configsvr/' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
                sed -i '/replication/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
                sed -i '/oplogSizeMB/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
                sed -i '/replSetName/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
                sed -i '/cacheSizeGB/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
                sed -i '/journal/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
                sed -i '/enabled: true/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
                sed -i '/engineConfig/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
                sed -i '/cacheSizeGB/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
                sed -i '/directoryForIndexes/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf

	elif [ "${ROLE}" = "mss" ]
	then

cat > ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf << EOF
systemLog:
 destination: file
 path: ${DIR}/mongodb${RPORT}/log/mongod.log
 logAppend: true
 logRotate: reopen
net:
 port: ${RPORT}
 maxIncomingConnections: 20000
sharding:
 configDB: $COFFIGDB
processManagement:
 fork: true
 pidFilePath: /data1/mongodb${RPORT}/mongod.pid
security:
 keyFile: /data1/mongodb${RPORT}/keyFile
###version
#mongo_version = mongodb30
EOF
	elif [ "${ROLE}" = "mda" ]
	then
		sed -i 's/enabled: true/enabled: false/g' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
		sed -i '/engine: wiredTiger/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
		sed -i '/wiredTiger:/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
		sed -i '/engineConfig:/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
		sed -i '/cacheSizeGB:/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
		sed -i '/directoryForIndexes: true/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
		sed -i '/collectionConfig:/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
		sed -i '/blockCompressor: snappy/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
		sed -i '/indexConfig:/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf
		sed -i '/prefixCompression: false/d' ${DIR}/mongodb${RPORT}/mongodb${RPORT}.cnf

	fi
fi


