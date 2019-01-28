#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

[ -z $ROOT ] && PARENT=$(dirname "$(readlink -f "$0")") || PARENT=$ROOT

# Get parameter
#-----------------------------------------------------------------------------------------
DEFAULT_PHP=`crudini --get $PARENT/config.ini php default`
INSTALL_V56=`crudini --get $PARENT/config.ini php php56`
INSTALL_V72=`crudini --get $PARENT/config.ini php php72`
INSTALL_V73=`crudini --get $PARENT/config.ini php php73`

# Change PHP repository
#-----------------------------------------------------------------------------------------
echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/sury-php.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com E5267A6C && apt update

# Install packages
#-----------------------------------------------------------------------------------------
[[ -d /run/php ]] || mkdir -p /run/php ; [[ -d /var/run/php ]] || mkdir -p /var/run/php

if [ $INSTALL_V56 == "yes" ] ; then
    apt install -y php5.6 php5.6-{bcmath,cgi,cli,common,curl,fpm,gd,gmp,imap,intl,json,mbstring,mysql,opcache,pgsql,readline,sqlite3,xml,xmlrpc,zip,zip} php-apcu
    crudini --set /etc/php/5.6/fpm/pool.d/www.conf 'www' 'listen' '/var/run/php/php5.6-fpm.sock'
    phpenmod curl opcache imagick fileinfo
    systemctl restart php5.6-fpm
fi

if [ $INSTALL_V72 == "yes" ] ; then
    apt install -y php7.2 php7.2-{bcmath,cgi,cli,common,curl,fpm,gd,gmp,imap,intl,json,mbstring,mysql,opcache,pgsql,readline,sqlite3,xml,xmlrpc,zip,zip}
    crudini --set /etc/php/7.2/fpm/pool.d/www.conf 'www' 'listen' '/var/run/php/php7.2-fpm.sock'
    phpenmod curl opcache imagick fileinfo
    systemctl restart php7.2-fpm
fi

if [ $INSTALL_V73 == "yes" ] ; then
    apt install -y php7.3 php7.3-{bcmath,cgi,cli,common,curl,fpm,gd,gmp,imap,intl,json,mbstring,mysql,opcache,pgsql,readline,sqlite3,xml,xmlrpc,zip,zip} php7.3-imagick php-pear
    crudini --set /etc/php/7.3/fpm/pool.d/www.conf 'www' 'listen' '/var/run/php/php7.3-fpm.sock'
    phpenmod curl opcache imagick fileinfo
    systemctl restart php7.3-fpm
fi

# Required package for all php version
apt install -y composer gettext gamin mcrypt imagemagick

# Configure packages
#-----------------------------------------------------------------------------------------
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "upload_max_filesize" "32M"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "max_execution_time"  "300"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "max_input_time"      "300"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "post_max_size"       "16M"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "display_errors"      "Off"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "cgi.fix_pathinfo"    "0"'  {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "memory_limit"        "768M"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "expose_php"          "Off"' {} \;

find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm"                      "ondemand"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.max_children"         "32"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.start_servers"        "2"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.min_spare_servers"    "4"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.max_spare_servers"    "8"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.max_requests"         "256"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.process_idle_timeout" "10s"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.status_path" "/status"' {} \;

bash $PARENT/snippets/set-php $DEFAULT_PHP
