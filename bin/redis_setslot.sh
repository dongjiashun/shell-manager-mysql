#!/bin/sh
### author: dongjiashun
### date: 2017-03-02
### func: migrate slot from src node to dest node


## src_server 10.11.11.11:6991
## dest_server 10.11.11.12:6992
## start_slot 5460
## end_slot   6000

rediscli=/usr/local/redis30/bin/redis-cli
#redistrib=/usr/local/redis30/bin/redis-trib.rb
redistrib=/usr/local/redis30/bin/check_trib.rb

function usage()
{
echo "
USAGE:
        migrate slot from src node to dest node
OPTION:
        -s src_server
        -d dest_server
        -S start_slot
        -E end_slot
        -a action
           value:check|run
           check:check cluster nodes & info
           run:migrate slot
           default value is check
        -h help

i.e. $0 -s 10.0.0.1:6991 -d 10.0.0.2:6992 -S 5000 -E 6000
i.e. $0 -s 10.0.0.1:6991 -d 10.0.0.2:6992 -S 5000 -E 6000 -a run
"
exit 1
}

while getopts s:d:S:E:a:h OPTION
do
   case "$OPTION" in
       s)src_server=$OPTARG
       ;;
       d)dest_server=$OPTARG
       ;;
       S)start_slot=$OPTARG
       ;;
       E)end_slot=$OPTARG
       ;;
       a)action=$OPTARG
       ;;
       h)usage;
         exit 0
       ;;
       *)usage;
         exit 1
       ;;
   esac
done

if [ -z $src_server ] || [ -z $dest_server ] || [ -z $start_slot ] || [ -z $end_slot ]
then
        usage
fi

if [ -z $action ]
then
        action=check
else
        if [ "$action" != "run" ] && [ "$action" != "check" ]
        then
                echo "[ERROR]: invalid option,please check!"
                usage
        fi
fi

src_host=`echo $src_server|awk -F':' '{print $1}'`
src_port=`echo $src_server|awk -F':' '{print $2}'`

dest_host=`echo $dest_server|awk -F':' '{print $1}'`
dest_port=`echo $dest_server|awk -F':' '{print $2}'`

src_nodeid=`$rediscli -p $src_port -h $src_host  cluster nodes |egrep $src_server |egrep myself,master|awk '{print $1}'`
dest_nodeid=`$rediscli -p $dest_port -h $dest_host  cluster nodes |egrep $dest_server |egrep myself,master|awk '{print $1}'`

if [ -z $src_nodeid ]
then
        echo "[ERROR]: please input src master of $src_oort,exit now!"
        exit 1
fi

if [ -z $dest_nodeid ]
then
        echo "[ERROR]: please input dest master of $dest_port,exit now!"
        exit 1

fi

function dest_import()
{

for slot in `seq ${start_slot} ${end_slot}`
do
        $rediscli -c -p $dest_port -h $dest_host  cluster setslot ${slot} IMPORTING  $src_nodeid
        if [ $? -ne 0 ]
        then
                echo "[ERROR]: importing $slot failed,please check!"
                exit 1
        else
                echo "[info]: importing $slot OK"
        fi
done

}

function src_migrating()
{
for slot in `seq ${start_slot} ${end_slot}`
do
        $rediscli -c -p  $src_port -h $src_host  cluster setslot ${slot} MIGRATING $dest_nodeid
        if [ $? -ne 0 ]
        then
                echo "[ERROR]: migrating $slot failed,please check!"
                exit 1
        else
                echo "[info]: migrating $slot OK"

        fi
done

}

function src_migrate_key()
{
for slot in `seq ${start_slot} ${end_slot}`
do
	while true
	do
		allkeys=`$rediscli -c -p $src_port -h $src_host cluster getkeysinslot ${slot} 20`
		
		echo allkeys:$allkeys
		
		if [  -z "${allkeys}" ]  
		then
			$rediscli -c -p $src_port -h $src_host cluster setslot ${slot} NODE $dest_nodeid
			if [ $? -ne 0 ]
			then
                                echo "[ERROR]: $src_server  NODE $slot failed,please check!"
                                exit 1
                        else
                                echo "[info]: $src_server  NODE $slot OK"
                        fi
                        $rediscli -c -p $dest_port -h $dest_host  cluster setslot ${slot} NODE $dest_nodeid
                        if [ $? -ne 0 ]
                        then
                                echo "[ERROR]: $dest_server node $slot failed,please check!"
                                exit 1
                        else
                                echo "[info]: $dest_server node $slot OK"
                        fi
                        break
                else
                        for key in ${allkeys}
                        do
                                echo "slot:${slot} key: ${key}"
                                $rediscli -c -p $src_port -h $src_host  MIGRATE $dest_host $dest_port  ${key} 0 7200
                                if [ $? -ne 0 ]
                                then
                                        echo "[ERROR]: $src_server migrate $key to $dest_server failed,please check!"
                                        exit 1
                                else
                                        echo "[info]: $src_server migrate $key to $dest_server OK"
                                fi
                        done
                fi
        done
done


}

function check_nodes()
{
echo $src_server
#$rediscli -p $src_port -h $src_host cluster saveconfig
sleep 3
$redistrib check $src_server
$rediscli -p $src_port -h $src_host cluster info

echo ""
echo $dest_server
#$rediscli -p $dest_port -h $dest_host cluster saveconfig
sleep 3
$redistrib check $dest_server
$rediscli -p $dest_port -h $dest_host cluster info

}


main()
{
if [ $action = check ]
then
        check_nodes
else

        dest_import
        src_migrating
        src_migrate_key
        check_nodes
fi



}

main

