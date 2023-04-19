mysql -h 127.0.0.1  -umstdba_mgr -p8ffe3589337b7d35 -P 3369 -Nse "select host from zabbix.hosts where host like '%3369%';" > zabbix_hostname

# 获取可用的从库
	    slaves=($(cat zabbix_hostname))
	    # 输出可用的从库
	    echo "Available slaves:"
	    for i in ${!slaves[@]}; do
		        echo "$(($i+1)). ${slaves[$i]}"
		done
