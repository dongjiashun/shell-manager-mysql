#!/bin/bash

# dongjs
while getopts "p:t:" opt; do
  case $opt in
    p)
      port=$OPTARG
      ;;
    t)
      database_type=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "for case $0 -p 3301 -t mysql " >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
# get paramer init
get_zabbix_info='select host from zabbix.hosts where host like "%3369%";'
# mysql info
user=mstdba_mgr
pwd='xxxxxxx'
zabbix_ip='172.26.1.2'
zabbix_port=3369
mysql -h$zabbix_ip -u$user -p$pwd -P$zabbix_port -Nse "${get_zabbix_info}" > zabbix_hostname

# check dbtype whether mysql
if [ $database_type == "mysql" ]; then
	slaves=($(cat zabbix_hostname))    
else
	echo "Unsupported database type: $database_type"
		    exit 1
fi

# data from zabbix.host get hostname
#mysql -h$host -u$user -p$pwd -P$port -Nse
# 输出可用的从库
echo "Available slaves:"
for i in ${!slaves[@]}; do
    echo "$(($i+1)). ${slaves[$i]}"
done

# select result from zabbixhost 
read -p "Select a db to login (1-${#slaves[@]}): " choice
if [[ $choice =~ ^[1-9]$ ]]; then
    slave=${slaves[$(($choice-1))]}
else
    echo "Invalid choice: $choice"
    exit 1
fi

# 登录到从库
echo "Logging in to $slave"_"$port ..."
ip=`echo $slave | awk -F'_' '{print $3}'`
mysql -h $ip -P $port -u $user -p$pwd
