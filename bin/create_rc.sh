#!/bin/sh
### author: dongjiashun
### date: 2017-03-23
### function: create a redis cluster
### [note]: six redis node must be startup firstly

PATH=$PATH:/usr/local/redis30/bin:/usr/local/redis32/bin:/usr/local/mysql56/bin:/usr/local/bin
export LANG=en_US.UTF-8

redis30dir=/usr/local/redis30/bin
redis32dir=/usr/local/redis32/bin


### redis-trib.rb create <masterhost>
### redis-trib.rb add-node --slave <slavehost> <masterhost>

function usage()
{
echo "
$0 [command] [option]
	-a action
	   value:create|add-node
	-s slavehost ip:port
	-m masterhost ip:port
	-v version
	value:3.0|3.2,default is 3.0
i.e. $0 -a create -m \"ip1:port1 ip2:port2 ip3:port3\"
i.e. $0 -a addnode -s sip1:port1 -m ip1:port1
"
exit 1
}

while getopts v:a:s:m:h OPTION
do
   case "$OPTION" in
       a)action=$OPTARG
       ;;
       s)slave=$OPTARG
       ;;
       m)master=$OPTARG
       ;;
       v)version=$OPTARG
       ;;
       h)usage
         exit 0
       ;;
       *)
           usage
            exit 1
          ;;
   esac
done

if [ -z  $version ]
then
	version=3.0
fi

if [ $version = 3.0 ]
then
	redisdir=$redis30dir
elif [ $version = 3.2 ];then
        redisdir=$redis32dir
fi


function create_rc()
{
if [ -z "$master" ]
then
	echo "[ERROR]: masterhost must be specified,please check!"
	exit 1
fi
$redisdir/redis-trib.rb create $master

}

### add a slave once
function addnode()
{
if [ -z "$slave" -o -z "$master" ]
then
	echo "[ERROR]: slave and master must be specified,please check!"
	exit 1
fi

$redisdir/redis-trib.rb add-node --slave $slave $master

}

if [ -z $action ]
then
	usage
elif [ $action = create ];then
	create_rc
elif [ $action = addnode ];then
	addnode
else
	usage
fi




