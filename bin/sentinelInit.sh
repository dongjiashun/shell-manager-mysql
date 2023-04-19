#!/bin/bash
### Author : dongjiashun
### Date : 2015-05-27
### Func : Init Redis Sentinel For some port,suport 2.8
### update 2016-08-08
### support 3.x

export LANG=en_US.UTF-8 
export PATH=$PATH:/usr/local/redis30/bin/:/usr/local/redis31/bin/:/usr/local/redis32/bin/


function  Usage(){
        echo "Usage: $0  [OPTION]
				-H redisMasterIP 
				-p master port  
				   valid value:6000-6999
				-c clustername 
				   default is:redis
			 	-d dir 
				default:/data 
				-v version
				   valid value:3.0,3.1,3.2
				   default value:3.0
"
        echo "       i.e.
		$0 -H 10.10.10.1 -p 6999 -c hatest -v 3.0  "
}

if [ $# -lt 6 ];then
        Usage
        exit 1
fi

while getopts H:p:d:c:v:h: OPTION
do
        case "$OPTION" in
                H)
                        hostip=$OPTARG
			;;
                p)
                        port=$OPTARG
                        ;;
                d)
                        dataDir=$OPTARG
                        ;;
                c)
                        clustname=$OPTARG
                        ;;
                v)
                        version=$OPTARG
                        ;;
                h)
			Usage
                        exit 0
                        ;;
                *)
                        Usage
                        exit 1
                        ;;
        esac
done

if [ -z $port ];then
        Usage
        exit 1
fi

if [ $(echo $port | bc 2>/dev/null) -eq 0 ];then
	echo "Port must be number!" 
	exit 1
fi
if [ $port -lt 6000 -o $port -gt 7000 ]
then
	echo "$port is invalid,please check!"
	exit 1
fi

if [ -z $hostip ];then
        Usage
        exit 1
fi

password=`echo redis_ewtonline_$port | md5sum | cut -c 1-16`

if [ -z $clustname ]
then
	clustname=redis
fi

if [ -z $dataDir ];then
	dataDir=/data
fi
homeDir="$dataDir/sentinel2$port"
confFile="$dataDir/sentinel2$port/sentinel2$port.cnf"

if [ -d $homeDir -o -f $confFile ];then
	echo "Sentinel2$port exists or confFile may have Initialized,Exit!"
	exit 1
fi
if [ -z $version  ]
then
	rversion=redis30
fi

if [ $version == 3.0 ]
then
	rversion=redis30
elif [ $version == 3.2 ];then
        rversion=redis32
elif [ $version == 3.1 ];then	
        rversion=redis31
else
        rversion=redis30
fi



portExists=`netstat -ntpl  | awk '{print $4}'| awk -F':' '{print $2}' | grep -w "2$port" | wc -l`
if [ $portExists -gt 0 ];then
        echo "Port already in use,Please Check!"
        exit 1
fi

mkdir -p $homeDir

echo "
# sentinel configuration file

#sentinel port
port 2$port
daemonize yes
dir "$homeDir"
pidfile "$homeDir/sentinel2${port}.pid"
logfile "$homeDir/sentinel2${port}.log"
bind 0.0.0.0

#setname
sentinel monitor ${clustname}$port $hostip $port 2
sentinel down-after-milliseconds ${clustname}$port 15000
sentinel failover-timeout ${clustname}$port 60000
sentinel auth-pass ${clustname}$port  $password
sentinel parallel-syncs ${clustname}$port 1

###redis_version=$rversion

" >$confFile

echo "Initilized over,every is ok!"
exit
