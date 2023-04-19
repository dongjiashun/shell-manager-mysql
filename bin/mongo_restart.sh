#!/bin/bash
### Author : dongjiashun
### Date : 2016-06-30
### Func : restart mongodb, including mongo_stop and mongo_start


PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/mysql56/bin:/usr/local/mongodb30/bin:/usr/local/redis28/bin:/home/dba/bin
export LANG=en_US.utf8

PORT=$2
if [ "$1" != '-p' ]
then
        echo "[ERROR] : Option error"
        echo "e.g. : bash $0 -p PORT"
        exit 1
else
        if [ "$2" = "" ]
        then
		echo "[ERROR] : Option error"
                echo "e.g. : bash $0 -p PORT"
                exit 1
        fi
fi

BDIR=/usr/local/bin


bash $BDIR/mongo_stop.sh  -p ${PORT}
sleep 5
bash $BDIR/mongo_start.sh  -p ${PORT}



