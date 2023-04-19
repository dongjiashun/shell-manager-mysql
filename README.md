# shell-manager-mysql
通过shell工程化管理和创建mysql。适合不会开发的小白，一步到位。脚本比较多。

##前言
  基本上满足百分之99的DBA。mysql数据库自动化创建数据库
  
  1.介绍下这个数据库脚本能干吗。？？？？估计很多人
    1。同一个服务器多个端口数据库。这个很多抠逼特喜欢干的。
    
  
![image](https://user-images.githubusercontent.com/30198924/232993803-3666ad3f-5dff-43ff-a784-f3c384ffa0ad.png)
就变成这样的目录。

## 数据环境准备
==========================================mysql57安装=====================================
账号密码权限：/usr/local/bin/grant.sql
https://rhel.pkgs.org/8/percona-x86_64/percona-toolkit-3.5.1-2.el8.x86_64.rpm.html

依赖包安装：
useradd dba
chmod 750 /usr/local/bin
yum install -y perl-DBI perl-DBD-MySQL
yum install -y perl-ExtUtils-Embed 
yum install -y perl-Digest-MD5
yum install -y perl-devel
yum install gcc libffi-devel openssl-devel python3-devel -y

## 操作命令
 venus_dbinit.sh -d /data3 -p 3369 -m 10 -s 0 -v mysql57 -e utf8mb4
 mysql_start.sh -P 3369
 mysql_stop.sh -P 3301
 
 ## 图文讲解
 

