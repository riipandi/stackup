#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi


# Setup repo first
source $ROOT/php/setrepo.sh

apt -y install composer php7.2 php7.2-{common,cli,cgi,fpm,bcmath,mbstring,json} \
php7.2-{gmp,readline,zip,sqlite3,intl,xml,xmlrpc,curl,zip,mysql,pgsql,imap,gd,opcache}

crudini --set /etc/php/7.2/fpm/php-fpm.conf  'www' 'listen' '/var/run/php/php7.2-fpm.sock'
systemctl restart php7.2-fpm
