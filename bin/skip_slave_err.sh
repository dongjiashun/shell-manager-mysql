#!/bin/sh


port=$1
errnum=$2

pt-slave-restart --user=mstdba_mgr --password=xxxxxxx --host=127.0.0.1 --port=$port --error-numbers=$errnum  --skip-count=1 

