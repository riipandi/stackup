#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

echo "deb https://packages.sury.xyz/php/ `lsb_release -cs` main" > /etc/apt/sources.list.d/sury-php.list
curl -sS https://packages.sury.xyz/php/apt.gpg | apt-key add -

apt update

apt -y install composer php7.2 php7.2-{common,cli,cgi,fpm,bcmath,mbstring,opcache,json} \
php7.2-{gmp,readline,zip,sqlite3,intl,xml,xmlrpc,curl,zip,mysql,pgsql,imap,gd}

crudini --set /etc/php/7.2/fpm/php-fpm.conf  'www' 'listen' '/var/run/php/php7.2-fpm.sock'
systemctl restart php7.2-fpm
