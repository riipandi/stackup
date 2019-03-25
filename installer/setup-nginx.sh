#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PARENT=$(dirname `dirname $(readlink -f $0)`) || PARENT=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

read -ep "Default PHP version ?                           : " -i "7.3" default_php

# Installing packages
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Installing Nginx packages...${NC}"
echo "deb http://ppa.launchpad.net/ondrej/nginx/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/nginx.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com E5267A6C && apt update
apt -y full-upgrade ; apt -y install {libpng,libssl,libffi,libexpat1}-dev libarchive-tools \
libimage-exiftool-perl libaugeas0 openssl haveged gamin nginx augeas-lenses python-dev

# Extra packages
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Downloading extra utilities...${NC}"
curl -L# "https://git.io/vN3Ff" -o /usr/local/bin/wp
curl -L# "https://git.io/fAFyN" -o /usr/local/bin/phpcs
curl -L# "https://git.io/fAFyb" -o /usr/local/bin/phpcbf
curl -L# "https://cs.sensiolabs.org/download/php-cs-fixer-v2.phar" -o /usr/local/bin/php-cs-fixer
chmod +x /usr/local/bin/* ; chown root: /usr/local/bin/*

# Download latest certbot
echo -e "\n${OK}Downloading certbot and trusted certificates...${NC}"
curl -L# https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt -o /etc/ssl/certs/chain.pem
curl -L# https://2ton.com.au/dhparam/4096 -o /etc/ssl/certs/dhparam-4096.pem
curl -L# https://2ton.com.au/dhparam/2048 -o /etc/ssl/certs/dhparam-2048.pem
wget https://dl.eff.org/certbot-auto -qO /usr/bin/certbot
chmod a+x /usr/bin/certbot

# Configure Nginx
#-----------------------------------------------------------------------------------------
systemctl enable --now haveged ; systemctl stop nginx
mkdir -p /var/www/html ; rm -fr /etc/nginx/*
cp -r $PARENT/config/nginx/* /etc/nginx/.
chown -R root: /etc/nginx

# Adjusting nginx configuration and default web page
sed -i "s|\("^worker_processes" * *\).*|\1$(nproc --all);|" /etc/nginx/nginx.conf
sed -i "s|\("^worker_connections" * *\).*|\1$(ulimit -n);|" /etc/nginx/nginx.conf
sed -i "s/HOSTNAME/$(hostname -f)/"          /etc/nginx/vhost.d/default.conf
sed -i "s/IPADDRESS/$(curl -s ifconfig.me)/" /etc/nginx/vhost.d/default.conf
cat /etc/nginx/manifest/default.php > /var/www/html/index.php
chown -R www-data: /var/www ; chmod -R 0775 /var/www

# SSL certifiacte for default vhost
#-----------------------------------------------------------------------------------------
if [[ ! -d "/etc/letsencrypt/live/$(hostname -f)" ]]; then
    certbot certonly --standalone --agree-tos --rsa-key-size 4096 \
    --register-unsafely-without-email --preferred-challenges http \
    -d "$(hostname -f)"
fi
systemctl restart nginx

# Default PHP-FPM on Nginx configuration
#-----------------------------------------------------------------------------------------
find /etc/nginx/manifest/ -type f -exec sed -i "s/php.*.-fpm/php\/php${default_php}-fpm/g" {} +
sed -i "s/php.*.-fpm/php\/php${default_php}-fpm/g" /etc/nginx/vhost.d/default.conf

# Nginx Amplify
#-----------------------------------------------------------------------------------------
read -ep "Do you want to use Nginx Amplify ?          y/n : " answer

if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Nginx Amplify Key                               : " amplify_key

    # Install Nginx Amplify
    API_KEY=$amplify_key bash <(curl -sLo- https://git.io/fNWVx)

    # Configure Nginx Amplify
    DB_ROOT_USER=`crudini --get /etc/mysql/conf.d/mysql.cnf mysql user`
    DB_ROOT_PASS=`crudini --get /etc/mysql/conf.d/mysql.cnf mysql password`
    DB_SOCKET_PATH="/var/run/mysqld/mysqld.sock"

    crudini --set /etc/amplify-agent/agent.conf 'listener_syslog-default' '​address' '127.0.0.1:13579'
    crudini --set /etc/amplify-agent/agent.conf 'credentials' 'hostname' `hostname -f`
    crudini --set /etc/amplify-agent/agent.conf 'extensions' 'phpfpm' 'True'
    crudini --set /etc/amplify-agent/agent.conf 'extensions' 'mysql'  'True'
    crudini --set /etc/amplify-agent/agent.conf 'mysql' 'unix_socket' $DB_SOCKET_PATH
    crudini --set /etc/amplify-agent/agent.conf 'mysql' 'password'    $DB_ROOT_PASS
    crudini --set /etc/amplify-agent/agent.conf 'mysql' 'user'        $DB_ROOT_USER

    mv /etc/nginx/conf.d/stub_status.{conf-disable,conf}
    systemctl restart amplify-agent
fi
