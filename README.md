# shell-manager-mysql
通过shell工程化管理上百台和创建mysql。适合不会开发的小白，一步到位。

1、同情很多看视频课程得。说啥bat出来得大牛。教学数据库。30多个小时一个屁脚本都憋不出来。憋出来得都是不能用得。几秒钟搞定得数据库主从。没必要这么浪费时间。

##前言
  基本上满足百分之99的DBA。mysql数据库自动化创建数据库
  
  1.介绍下这个数据库脚本能干吗。？？？？估计很多人
  
    1.同一个服务器多个端口数据库。这个很多抠逼特喜欢干的。
    
    2.单个挂载盘。多个端口。当然你也可以一个端口
    
    
  
![image](https://user-images.githubusercontent.com/30198924/233007037-350f6e65-922d-4a7d-a2f5-e9431e793110.png)

就变成这样的目录。

## 数据环境准备
==========================================mysql57安装=====================================
数据库安装包下载：

账号密码权限：

/usr/local/bin/grant.sql  通过这个sql文件。初始化数据库得时候创建用户和权限

https://rhel.pkgs.org/8/percona-x86_64/percona-toolkit-3.5.1-2.el8.x86_64.rpm.html

依赖包安装：

数据库版本：Percona-Server-5.7.40-43-Linux.x86_64.glibc2.17.tar.gz（这个是免安装版本，你要是下载是二进制安装就傻逼了。我这个时间段最新。你看得时候不知道是不是了）
liunx环境：能跑shell都行
数据库安装目录：/usr/local/  当然你看我脚本也可以自己改

授权：脚本是dba用户执行得。你得规范点
useradd dba
chmod 750 /usr/local/bin


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

  p 是端口
  
  m 是主库ip 不多说了。这个不懂好死了

![image](https://user-images.githubusercontent.com/30198924/233006505-fa8c2f83-254e-4588-b9b1-ffd5db1cdcba.png)

  
  基本一个主从就完事了。你以为完事了。no no 不然我上传这么多搞屁啊。
  
  以上基本可以实现数据库主从操作。已经本地通过dblogin 快速登入，但是既然是工程化脚本，那不得管理上百个服务器才行。单机搞pp
  
  # 通过以上得方法可以搭建。单个目录多个数据库。基本几秒钟就搞定了。
  
  # 如果是1000 台服务器。你只能通过shell。这边暂时不考虑自动化平台上可以执行sql。只能通过shell管理上百上千得数据库，你怎么登入。一台一台登入服务器。让后dblogin 一个一个登入吗。兄弟。 那就傻逼了
  
  给你看下哈
  
![image](https://user-images.githubusercontent.com/30198924/233009584-05659f1f-b39a-4351-b6ed-6f8408d83d73.png)

通过这种方式登入数据库，就完美解决问题。我这套数据库体系是整套。集成比较多。后面再分享把

这个脚本要集成zabbix 里面得一个hosts 表。获取到hostname。。。。。。这次就分享到这把。
  
