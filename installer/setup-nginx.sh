#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PARENT=$(dirname `dirname $(readlink -f $0)`) || PARENT=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

read -ep "Default PHP version for virtualhost?            : " -i "7.3" default_php

# Installing packages
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Installing Nginx packages...${NC}"
echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/nginx.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C300EE8C > /dev/null 2>&1 && apt update
apt -y full-upgrade ; apt -y install {libpng,libssl,libffi,libexpat1}-dev libarchive-tools \
libimage-exiftool-perl libaugeas0 openssl haveged gamin nginx augeas-lenses python-dev

# Download latest certbot
echo -e "\n${OK}Downloading certbot and trusted certificates...${NC}"
curl -L# https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt -o /etc/ssl/certs/chain.pem
curl -L# https://2ton.com.au/dhparam/4096 -o /etc/ssl/certs/dhparam-4096.pem
curl -L# https://2ton.com.au/dhparam/2048 -o /etc/ssl/certs/dhparam-2048.pem
wget https://dl.eff.org/certbot-auto -qO /usr/bin/certbot
chmod a+x /usr/bin/certbot

# Configure Nginx
#-----------------------------------------------------------------------------------------
systemctl enable --now haveged && systemctl stop nginx && rm -fr /var/www/html
rm -fr /etc/nginx/ ; cp -r $PWD/config/nginx/ /etc/ ; chown -R root: /etc/nginx
sed -i "s|\("^worker_processes" * *\).*|\1$(nproc --all);|" /etc/nginx/nginx.conf
sed -i "s|\("^worker_connections" * *\).*|\1$(ulimit -n);|" /etc/nginx/nginx.conf
sed -i "s/HOSTNAME/$(hostname -f)/"          /etc/nginx/vhost.d/default.conf
sed -i "s/IPADDRESS/$(curl -s ifconfig.me)/" /etc/nginx/vhost.d/default.conf
cat /etc/nginx/manifest/default.php > /var/www/html/index.php

chown -R www-data: /var/www ; chmod -R 0775 /var/www
rm -f /var/www/html/index.nginx-debian.html

# SSL certifiacte for default vhost
#-----------------------------------------------------------------------------------------
[[ ! -d "/etc/letsencrypt/live/$(hostname -f)" ]] && certbot certonly --standalone --agree-tos --rsa-key-size 4096 --register-unsafely-without-email --preferred-challenges http -d "$(hostname -f)"
systemctl restart nginx

# Default PHP-FPM on Nginx configuration
#-----------------------------------------------------------------------------------------
find /etc/nginx/manifest/ -type f -exec sed -i "s/php.*.-fpm/php\/php${default_php}-fpm/g" {} +
sed -i "s/php.*.-fpm/php\/php${default_php}-fpm/g" /etc/nginx/vhost.d/default.conf
systemctl restart nginx

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

# Crontab for renewing LetsEncrypt certificates
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Configuring cron for renewing certificates...${NC}"
echo "01 01 01 */3 * /usr/local/bin/ssl-renew >/var/log/ssl-renew.log" > /tmp/ssl_renew
crontab /tmp/ssl_renew ; rm /tmp/ssl_renew
