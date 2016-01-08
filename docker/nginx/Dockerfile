FROM ubuntu:wily

MAINTAINER Andrii Bilorus <andrii.bilorus@gmail.com>

RUN apt-get update
RUN apt-get install -y nginx && \
    mkdir -p /var/www/shsh && chown www-data:www-data /var/www/shsh

COPY ./nginx.conf /etc/nginx/
COPY ./fastcgi.conf /etc/nginx/

EXPOSE 80

CMD /usr/sbin/nginx -g "daemon off;"
