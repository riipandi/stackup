#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

echo "deb https://packages.sury.xyz/php/ `lsb_release -cs` main" > /etc/apt/sources.list.d/sury-php.list
curl -sS https://packages.sury.xyz/php/apt.gpg | apt-key add -

apt update

apt -yqq install php7.3 php7.3-{common,cli,cgi,fpm,bcmath,mbstring,opcache,json} \
php7.3-{gmp,readline,zip,sqlite3,intl,xml,xmlrpc,curl,zip,mysql,pgsql,imap,gd}

crudini --set /etc/php/7.3/fpm/php-fpm.conf  'www' 'listen' '/var/run/php/php73-fpm.sock'

phpenmod curl opcache imagick fileinfo
systemctl restart php7.3-fpm
