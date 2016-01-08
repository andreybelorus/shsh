#!/bin/bash

. ./settings.sh

mariadb() {
    docker rm -f ${dbhost} || echo 
    docker run -d -it --name ${dbhost} -e MYSQL_ROOT_PASSWORD=${dbrootpass} -p 127.0.0.1:3306:3306 mariadb:latest
    echo Waiting for datadase start 
    for ((i=0;i<30;i++)); do
        sleep 1 && printf "."
    done
}

fcgi() {
    [ -d /var/log/docker/fcgi ] && rm -rf /var/log/docker/fcgi/* || mkdir -p /var/log/docker/fcgi
    cd docker/fcgi
    docker rm -f fcgi || echo
    docker build --tag fcgi .
    docker run -d -it --name fcgi --link ${dbhost}:${dbhost} -v /var/log/docker/fcgi:/var/log -v /var/www/shsh:/var/www/shsh fcgi
    cd -
}

nginx() {
    [ -d /var/log/docker/nginx ] && rm -rf /var/log/docker/nginx/* || mkdir -p /var/log/docker/nginx
    cd docker/nginx
    docker rm -f nginx || echo
    docker build --tag nginx .
    docker run -d -it -p 80:80 --name nginx --link fcgi:fcgi --link ${dbhost}:${dbhost} -v /var/www/shsh:/var/www/shsh -v /var/log/docker/nginx:/var/log/nginx nginx
    cd -
}

cgi() {
    [ -d /var/www/shsh ] && rm -rf /var/www/shsh/* || mkdir -p /var/www/shsh 
    cp ./settings.sh /var/www/shsh
    cp ./test.sh /var/www/shsh
    cp -R view /var/www/shsh
}

cgi
mariadb
cd database
./db.sh
cd -
fcgi
nginx
