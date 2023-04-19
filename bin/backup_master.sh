#!/bin/sh
### author:dongjiashun
### date:2014-10-30
### function: hot backup on master
### full backup with innobackupex 2.2.4


PATH=/usr/local/px22/bin:/sbin:/usr/sbin:/usr/local/sbin:/usr/bin:/bin:/usr/local/bin:/usr/local/mysql56/bin/:
export LANG=en_US.UTF-8

###ulimit -HSn 327680

date=`date  +%F`


user=mstdba_mgr
password=xxxxxxx
host=127.0.0.1
baklog=/tmp/backup_master.log

localip=`ip addr | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d / -f 1 |head -n1`



usage()
{
echo "  
usage:
                sh backup_master.sh -p port  -t threadparallel
                -p: the master port
                -t: the number of parallel,the max value is 
                the cpu numbers,default value is 2

                e.g. 
                sh backup_master.sh -p 3002 -t 4

"

}

while getopts p:t:h OPTION
do
        case "$OPTION" in
          p)port=$OPTARG;;
          t)threadparallel=$OPTARG;;
          h) usage;
             exit 1;;
          *) echo "Please check your options! ";
             usage
             exit 1
            ;;
        esac
done

INNOBIN=/usr/local/px22/bin


function findatadir()
{
for d in /data/ /data1/ /home/dba/
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
findatadir

backup_m()
{

bakdir=${datadir}backup/mysql$port
mkdir -p $bakdir
[ -z $threadparallel ] && threadparallel=2
mkdir -p $bakdir
innlog=$bakdir/$date/TODO_${port}.log

echo "" >> $baklog
echo "" >> $baklog
echo "`date '+%F %T'`   $port begins to backup" >  $baklog
$INNOBIN/innobackupex  --defaults-file=$FILE  --ibbackup=$INNOBIN/xtrabackup  --rsync --user=$user  --password=$password    --host=$host  --port=$port   --no-timestamp   --parallel=$threadparallel    --tmpdir=${datadir}backup/mysql$port  $bakdir/$date  1>/dev/null

if [ $? -eq 0 ]
then

        echo "`date '+%F %T'`   $port begins to apply log" >>  $baklog
        $INNOBIN/innobackupex  --ibbackup=$INNOBIN/xtrabackup  --defaults-file=$bakdir/$date/backup-my.cnf --use-memory=1G --apply-log    --tmpdir=$bakdir   $bakdir/$date  1>/dev/null
        if [ $? -eq 0 ]
        then


                echo "#############################" >>  $baklog

                echo "`date '+%F %T'`   $port apply log OK" >>  $baklog
                cp  $FILE $bakdir/$date
                echo "`date '+%F %T'`   please modify server_id,and chown ,and  make a new slave with CHANGE MASTER command" >>  $baklog

                        master_log_file=`cat $bakdir/$date/xtrabackup_binlog_info |awk '{print $1}'`
                        master_log_pos=`cat $bakdir/$date/xtrabackup_binlog_info |awk '{print $2}'`

                        echo " exec the cmds on slave:
                                0. modify server_id in my$port.cnf
                                   chown -R my$port.mysql /home/dba/mysql$port
                                1. mysql_start.sh -P $port
                                2. change master to master_host='$localip', master_user='mreplic', master_password='699c6929cc14680c',master_port=$port,master_log_file='$master_log_file',master_log_pos=$master_log_pos;
                                4. start slave;
                                   show slave status\G


" >> $innlog

cat $innlog  $baklog
#               fi


        else
                echo "`date '+%F %T'` $port apply log error" >> $baklog
                exit 1
        fi
else
        echo "`date '+%F %T'`  $port innobackupex error" >> $baklog
        exit 1
fi
}


function rsync2db1()
{

### compress backup files
cd $bakdir && tar -zcvf ${port}_${date}.tar.gz $date
if [ $? -eq 0 ]
then

        cd $bakdir && rm -rf $date
else
        echo "`date '+%F %T'` tar -zcvf ${port}_${date}.tar.gz $date failed,please check!" >> $baklog
	[ -f ${port}_${date}.tar.gz ] && rm -rf ${port}_${date}.tar.gz
        exit 1
fi

}



main() {
        if [ -z $port ]
        then
                usage

        elif [ $port -ge 3000 ] && [ $port -lt 4000 ]
        then
                backup_m
		sleep 10
#		rsync2db1
        fi

}

main


