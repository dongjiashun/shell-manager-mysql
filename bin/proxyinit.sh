#!/bin/sh





#localip="`ip addr | grep "inet " | grep -v 127.0.0.1 |egrep -v secondary | awk '{print $2}' | cut -d / -f 1 | egrep ^188`"
localip="`ip addr | grep "inet " | grep -v 127.0.0.1 |egrep -v secondary | awk '{print $2}' | cut -d / -f 1 | egrep ^10`"

proxybase=/usr/local/mysql-proxy

function usage()
{
echo "usage:$0 [OPTION]
	-p mysql port
	-d mysql database,which is the save as the user
	-m master ip
	-s slave ip,
	   many slaves are comma-delimited
	-c client ip
           many clients are comma-delimited

"
echo "
	e.g. $0 -p 3904 -d dbatest -m 10.0.0.16 -s 10.0.0.76,10.0.0.77 -c 10.0.0,127.0.0.1
"
exit 1

}


while getopts p:d:m:s:c:h OPTION
do
   case "$OPTION" in
       p)port=$OPTARG
       ;;
       d)db=$OPTARG
       ;;
       m)master=$OPTARG
       ;;
       s)slave=$OPTARG
       ;;
       c)client=$OPTARG
       ;;
       h)usage;
         exit 0
       ;;
       *)usage;
         exit 1
       ;;
   esac
done

if [ -z $port ] || [ -z $master ] || [ -z $slave ]
then
	echo "[ERROR]: please input port,master,slave"
	usage

fi

function init_proxy()
{

user=$db
origpass=`echo ${user}${port}|md5sum|cut -c 1-16`
password=`$proxybase/bin/encrypt $origpass`

echo "
server:${localip}:1${port}
user:$user
password:$origpass
client ips:$client
"

proxyslaves=""
slaves=`echo ${slave//,/ }`
for s in $slaves
do
        if [ AA"$proxyslaves" = AA ]
        then
                proxyslaves="${s}:${port}"
        else
                proxyslaves="$proxyslaves ${s}:${port}"
        fi
done

slaves=`echo ${proxyslaves// /,}`



cat >$proxybase/conf/${port}.cnf << EOF
[mysql-proxy]
admin-username=mstdba_mgr
admin-password=xxxxxxx
admin-lua-script=/usr/local/mysql-proxy/lib/mysql-proxy/lua/admin.lua
log-level=message
log-path=/usr/local/mysql-proxy/log
daemon=true
keepalive=true
event-threads=4
instance=$port
proxy-address=0.0.0.0:1$port
admin-address=0.0.0.0:2$port
proxy-backend-addresses=${master}:$port
proxy-read-only-backend-addresses=$slaves
client-ips=$client
pwds=zabbix:tqNqadlgen+avuD/y+KfMRryz+hZmUy9,mst_monitor:08qw2QDhCQZ5bdgubUBNmhryz+hZmUy9,$user:$password
charset=utf8
sql-log=ON
EOF

}

init_proxy



