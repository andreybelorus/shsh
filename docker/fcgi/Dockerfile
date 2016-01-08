FROM ubuntu:wily

MAINTAINER Andrii Bilorus <andrii.bilorus@gmail.com>

RUN apt-get update
RUN apt-get install -y mysql-client fcgiwrap bc && mkdir -p /var/www/shsh  

EXPOSE 9000

CMD [ "/usr/sbin/fcgiwrap", "-s", "tcp:0.0.0.0:9000" ]
