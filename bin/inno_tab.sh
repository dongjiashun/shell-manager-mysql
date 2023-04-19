#!/bin/sh
### atuhor:dongjiashun
### date:2017-12-20
### function:hot backup a table or a db with percona xtrabackup


paTH=$PATH:/usr/local/bin:/usr/local/mysql56/bin:/usr/local/px22/bin
export LANG=en_US.UTF-8


user=mstdba_mgr
password=xxxxxxx
host=127.0.0.1




function  usage()
{
echo "usage:    $0 -p port  -t <db.table> "
echo "usage:    $0 -p port -d <dB> "
echo "e.g. $0 -p 3001 -t dbtest1.t1"
echo "e.g. $0 -p 3001 -d dbtest1"
}



while getopts p:ht:d: OPTION
do
   case "$OPTION" in
       p)port=$OPTARG
       ;;
       h)usage
         exit 1
       ;;
       t)tab=$OPTARG
       ;;
       d)db=$OPTARG
       ;;
       *)usage
         exit 1
       ;;
   esac
done

if [ -z "$port" ]
then
        echo "[ERROR]: please specify port,exit..."
	usage

fi

if [ -z "$tab" ] && [ -z "$db" ]
then
	echo "[ERROR]: please specify tab or db,exit..."
	usage
elif [ ! -z "$tab" ] && [ ! -z "$db" ];then
        echo "[ERROR]: please specify tab or db,exit..."
        usage
fi

datadir=`ps -ef|grep /usr/local|grep mysql$port | awk -F'--datadir' '{print $2}'  |awk '{print $1}'  |awk -F'=' '{print $2}'`
if [ -z "$datadir" ] 
then
	echo "[ERROR]: no found mysql$port,exit..."
	exit 1
else
	basedir=`echo $datadir|awk -F'/' '{print $2}'`
	mkdir -p /$basedir/dbtab_backup/mysql$port
	dt=`date +%s`
fi


function backup_tab()
{

### backup 
#innobackupex --export --include="$tab"  --user=$user --password=$password --host=127.0.0.1 --port=$port --defaults-file=${datadir}my${port}.cnf --no-timestamp   /$basedir/dbtab_backup/mysql$port/${tab}.$dt  >/dev/null
innobackupex --defaults-file=${datadir}my${port}.cnf --export --include="$tab"  --user=$user --password=$password --host=127.0.0.1 --port=$port   --no-timestamp   /$basedir/dbtab_backup/mysql$port/${tab}.$dt  >/dev/null
if [ $? -ne 0 ]
then
	echo "[ERROR]: innobackupex --export $tab failed,exit..."
	exit 1
fi
innobackupex --apply-log  --export  /$basedir/dbtab_backup/mysql$port/${tab}.$dt  >/dev/null
if [ $? -ne 0 ]
then
	echo "[ERROR]: innobackupex --apply-log $tab failed,exit..."
	exit 1
else
	echo "[info]: hot backup $tab ok!"

	### dump table schema
	tab_db=`echo $tab|awk -F'.' '{print $1}'`
	tab_tab=`echo $tab|awk -F'.' '{print $2}'`

	/usr/local/mysql56/bin/mysqldump -u$user -p$password  -h 127.0.0.1 -P $port  $tab_db $tab_tab -d > /$basedir/dbtab_backup/mysql$port/${tab}.$dt/${tab}_schema.sql


fi

}


function backup_db()
{

### backup 
#innobackupex --export --databases="$db"  --user=$user --password=$password --host=127.0.0.1 --port=$port --defaults-file=${datadir}my${port}.cnf --no-timestamp   /$basedir/dbtab_backup/mysql$port/${db}.$dt  >/dev/null
innobackupex --defaults-file=${datadir}my${port}.cnf  --export --databases="$db"  --user=$user --password=$password --host=127.0.0.1 --port=$port  --no-timestamp   /$basedir/dbtab_backup/mysql$port/${db}.$dt  >/dev/null
if [ $? -ne 0 ]
then
        echo "[ERROR]: innobackupex --export $db failed,exit..."
        exit 1
fi
innobackupex --apply-log  --export  /$basedir/dbtab_backup/mysql$port/${db}.$dt >/dev/null
if [ $? -ne 0 ]
then
        echo "[ERROR]: innobackupex --apply-log $db failed,exit..."
        exit 1
else
        echo "[info]: hot backup $db ok!"

	### dump all tables schema of th db
	/usr/local/mysql56/bin/mysqldump -u$user -p$password  -h 127.0.0.1 -P $port -B $db  -d > /$basedir/dbtab_backup/mysql$port/${db}.$dt/${db}_schema.sql

fi

}

function restore_db_tab()
{
if [ ! -z "$tab" ]
then
	echo "【 restore a table 】
1 执行sql语句建表
2 废弃tablespace
ALTER TABLE <table_name> DISCARD TABLESPACE;
3 拷贝表文件
拷贝表对应的.idb .cfg到表文件所在目录
4 导入备份数据：
ALTER TABLE <table_name> IMPORT TABLESPACE;

">/$basedir/dbtab_backup/mysql$port/${tab}.$dt/TODO
else
        echo "【 restore a db 】
1 执行sql语句建表
2 废弃tablespace
针对该db的每个table，执行如下操作：
ALTER TABLE <table_name> DISCARD TABLESPACE;
3 拷贝表文件
拷贝表对应的.idb .cfg到表文件所在目录
4 导入备份数据：
ALTER TABLE <table_name> IMPORT TABLESPACE;

">/$basedir/dbtab_backup/mysql$port/${db}.$dt/TODO
fi

}


if [ ! -z "$tab" ]
then
        backup_tab
elif [ ! -z "$db" ];then
        backup_db
else
        echo "[ERROR]: invalid parameter,exit..."
        usage
fi

restore_db_tab



