# shsh

Web application for testing Unix shell skills. Actualy it doesn't depends on questions topic but in other case you should a little bit change scripts and html-files.

###Requirements
* bash
* docker
* mysql-client

###Installation.
* Set up configuration values in settings.sh. It is anougth to set root password for database in most cases. This password is used only for container database.
* Fill file question.txt with questions and answers. Follow the rules which you can find in the file. You can find examples in the questions.txt as well.
* Run `sudo ./install.sh`. This script creates three docker containers with: nginx, fcgiwrap, mariadb.

###Demo
