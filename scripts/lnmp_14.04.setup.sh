#!/bin/bash
#  2016.11. By  RichardChou

if [ `id -u` -ne 0 ]
then
  echo "Please start this script with root privileges!"
  echo "Try again with sudo."
  exit 0
fi


#################################################################
# lnmp

cd `dirname $0`
root=`pwd`
date
echo "work path: $root ";

mysql_usr='root'
mysql_password='mysqlpwd'

if [ `id -u` -ne 0 ];then
   echo "this backup script must be exec as root."
   exit
fi

echo "set timezone to Asia/Shanghai for ubuntu only.";
#cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

function execSql(){
  echo $mysql_usr
  if [ "$1" = "" ];then
    echo "need sql!!!,exit";
    exit -1;
  fi
  
  echo "sql:$1"
  mysql -u${mysql_usr} -p${mysql_password} -e "$1"
}

echo "install nginx+php-fpm"



echo "add php7 source:"
apt-get install -y language-pack-en-base
LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php

apt-get update 
apt-get -y install dos2unix screen lrzsz  vim  curl  tree
apt-get -y install build-essential
 

#安装nginx
apt-get -y install nginx

#php环境搭建
apt-get -y install libmcrypt-dev mcrypt 
apt-get -y install php7.0-cli php7.0-cgi php7.0-fpm php7.0-mcrypt php7.0-mysql 
apt-get -y install php7.0-common php7.0-dev php-apc php7.0-curl  php7.0-gd php7.0-idn php-pear php7.0-memcache php7.0-ming php7.0-recode php7.0-tidy php7.0-xmlrpc php7.0-xsl php7.0-xml


apt-get -y install git bash-completion

cd /etc/php/7.0/fpm/conf.d
ln -s ../../mods-available/mcrypt.ini 20-mcrypt.ini
cd -
#memcached
#apt-get -y install libmemcached-dev libmemcached6  php5-memcached  cyrus-sasl2-dbg   libsasl2-dev cloog-ppl  
apt-get -y install   libsasl2-dev cloog-ppl  

 
#重启nginx php5-fpm  
#/etc/init.d/php5-fpm restart 
/etc/init.d/php7.0-fpm  restart 
/etc/init.d/nginx restart

#apt-get -y install  phpmyadmin
mkdir -p  /web/www 2>/dev/null
cd /web
mkdir logs  2>/dev/null
mkdir gits 2>/dev/null
#ln -s /usr/share/phpmyadmin /web/www  2>/dev/null

#php测试文件
cd /web/www
touch index.php
echo '<?php echo date("Y-m-d H:i:s")." it works,just only for test."; ?>' > index.php


#配置vim
cd

cat > ~/.vimrc <<EOF
set nu
color desert
set nocompatible
set backspace=indent,eol,start
EOF

echo '**********nginx************'
cd /etc/nginx
cat >nginx.conf <<EOF
#nginx config create at `date`
user  www-data;

worker_processes 4;

pid        /var/run/nginx.pid;

#Specifies the value for maximum file descriptors that can be opened by this process. 
worker_rlimit_nofile 65535;

events 
{
  use epoll;
  worker_connections 768;
}

http 
{
  include       /etc/nginx/mime.types;
  default_type  application/octet-stream;

  #charset  gb2312;
      
  server_names_hash_bucket_size 128;
  client_header_buffer_size 32k;
  large_client_header_buffers 4 32k;
  client_max_body_size 8m;
      
  sendfile on;
  tcp_nopush     on;

  keepalive_timeout 60;

  tcp_nodelay on;

  fastcgi_connect_timeout 300;
  fastcgi_send_timeout 300;
  fastcgi_read_timeout 300;
  fastcgi_buffer_size 64k;
  fastcgi_buffers 4 64k;
  fastcgi_busy_buffers_size 128k;
  fastcgi_temp_file_write_size 128k;

  gzip on;
  gzip_min_length  1k;
  gzip_buffers     4 16k;
  gzip_http_version 1.0;
  gzip_comp_level 2;
  gzip_types       text/plain application/x-javascript text/css application/xml;
  gzip_vary on;

  #limit_zone  crawler  $binary_remote_addr  10m;

  log_format  access  '\$remote_addr - [\$time_local] - "Host:\$host" "Req:\$request" "\$upstream_addr"'
                  ' "status:\$status" \$body_bytes_sent "\$http_referer" '
                  '"\$http_user_agent" "\$http_x_forwarded_for" "\$http_content_length"';
                  
  access_log  /web/logs/access.log  access;
  error_log  /web/logs/error.log ;
    

  include /etc/nginx/vhosts.d/*.conf;
}

EOF

mkdir vhosts.d  2>/dev/null
cd vhosts.d


cat >default.conf <<EOF

server
  {
    listen       80;
    server_name   127.0.0.1 ;
    index index.html index.htm index.php;
    root  /web/www/;
 

	location ~  .sql\$ {
          deny all;
        }

	location ~ .*\.(php|php5)?\$
	{      
		fastcgi_pass  unix://var/run/php/php7.0-fpm.sock;
		#fastcgi_pass  127.0.0.1:9000;
		fastcgi_index index.php;
		fastcgi_param  SCRIPT_FILENAME   \$document_root\$fastcgi_script_name;
		include        /etc/nginx/fastcgi_params;
	}


	location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)\$
	{
		expires      30d;
	}

	location ~ .*\.(js|css)?\$
	{
		expires      1h;
	}   

}

  
  
EOF
cd -
/etc/init.d/nginx restart
#不生成pyc
echo 'export PYTHONDONTWRITEBYTECODE=1' >> /etc/bash.bashrc

if [ -d remote_node ];then
	cp  -R remote_node/* /web/www/
fi
echo "install mysql,user: $mysql_usr, password:$mysql_password "
sleep 2

echo mysql-server mysql-server/root_password password $mysql_password | sudo debconf-set-selections  
echo mysql-server mysql-server/root_password_again password $mysql_password | sudo debconf-set-selections  
#设定root 用户及其密码 $mysql_password
apt-get install -y  mysql-server-5.6


checkmysql=`ps axuf|grep mysql|grep -v grep`
if [ -z "$checkmysql" ];then 
  echo  'mysql must need!';
  exit
fi

mysql  -u${mysql_usr} -p${mysql_password}  -e "select version()"
if [ 0 eq $? ];then
  echo "mysql root user failed.exit.";
  exit
fi

#apt-get update
apt-get install  -y build-essential mysql-client-5.6  libmysqld-dev



 
apt-get install  -y  python-pip
echo "[done]"

