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
第一步创建：
 
     venus_dbinit.sh -d /data3 -p 3369 -m 10 -s 0 -v mysql57 -e utf8mb4

第二步 开启数据库

     mysql_start.sh -P 3369

第三步

    mysql_stop.sh -P 3301
 

 ## 图文讲解
 

创建数据库

### 创建数据库
venus_dbinit.sh -d /data3 -p 3369 -m 10 -s 0 -v mysql57 -e utf8mb4
image.png

-d 数据库安装目录

-p 端口

-m 数据库内存设置

-s 主从设置 0 为主库。1位从库

-v 数据库版本
![image](https://user-images.githubusercontent.com/30198924/233004851-d31ebe12-c68a-4e46-9cfe-742e535e46a5.png)

### 第二步数据库启动
![image](https://user-images.githubusercontent.com/30198924/233004890-8bdedc67-b5b5-4af5-a369-01dbbb56ea66.png)


### 登入数据库
![image](https://user-images.githubusercontent.com/30198924/233004928-d416083e-87c9-4aa4-9054-a79bf6f26ace.png)

基本几秒钟就搞定。如果就到这就完事。那就不用完了。哪有DBA就创建一个数据库的。玩个得啊。

#主从架构
  
  基于上面得操作继续。在从库数据库安装
  
  ![image](https://user-images.githubusercontent.com/30198924/233006057-2ea9c6c9-cc77-4b5a-8848-5fff6ea111fd.png)
  
 创建从库：
 
 venus_mysql_slaveof.sh -p 3309 -m 172.26.1.2


![image](https://user-images.githubusercontent.com/30198924/233006505-fa8c2f83-254e-4588-b9b1-ffd5db1cdcba.png)

  
  基本一个主从就完事了。
