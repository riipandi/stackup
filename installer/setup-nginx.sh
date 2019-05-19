#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PWD=$(dirname `dirname $(readlink -f $0)`) || PWD=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

touch "$PWD/stackup.ini"
if [ -f "$PWD/stackup.ini" ]; then
    [[ $(cat "$PWD/stackup.ini" | grep -c "default_php") -eq 1 ]] && default_php=$(crudini --get $PWD/stackup.ini '' 'default_php')
    [[ -z "$default_php" ]] && read -ep "Default PHP version ?                           : " -i "7.3" default_php
fi

# Installing packages
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Installing Nginx packages...${NC}"
echo "deb [arch=amd64] http://nginx.org/packages/mainline/ubuntu/ `lsb_release -cs` nginx" > /etc/apt/sources.list.d/nginx.list
curl -sS http://nginx.org/keys/nginx_signing.key | apt-key add - && apt update
apt -y full-upgrade ; apt -y install {libpng,libssl,libffi,libexpat1}-dev libarchive-tools \
libimage-exiftool-perl libaugeas0 openssl haveged gamin nginx augeas-lenses python-dev

# Download latest certbot
echo -e "\n${OK}Downloading certbot and trusted certificates...${NC}"
curl -L# https://dl.eff.org/certbot-auto -o /usr/bin/certbot ; chmod a+x /usr/bin/certbot
curl -L# https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt -o /etc/ssl/certs/chain.pem
curl -L# https://2ton.com.au/dhparam/4096 -o /etc/ssl/certs/dhparam-4096.pem
curl -L# https://2ton.com.au/dhparam/2048 -o /etc/ssl/certs/dhparam-2048.pem

# SSL certifiacte for default vhost
#-----------------------------------------------------------------------------------------
if [ ! -d "/etc/letsencrypt/live/$(hostname -f)" ]; then
    certbot certonly --standalone --agree-tos --rsa-key-size 4096 --register-unsafely-without-email --preferred-challenges http -d "$(hostname -f)"
fi
systemctl restart nginx

# Configure Nginx
#-----------------------------------------------------------------------------------------
systemctl enable --now haveged && systemctl stop nginx && rm -fr /var/www/html
rm -fr /etc/nginx/ ; cp -r $PWD/config/nginx/ /etc/ ; mkdir -p /etc/nginx/vhost.d
sed -i "s|\("^worker_processes" * *\).*|\1$(nproc --all);|" /etc/nginx/nginx.conf
sed -i "s|\("^worker_connections" * *\).*|\1$(ulimit -n);|" /etc/nginx/nginx.conf
sed -i "s/HOSTNAME/$(hostname -f)/"          /etc/nginx/conf.d/default.conf
sed -i "s/IPADDRESS/$(curl -s ifconfig.me)/" /etc/nginx/conf.d/default.conf
chown -R root: /etc/nginx ; chown -R www-data: /var/www ; chmod -R 0775 /var/www
mkdir -p /var/www/html ; cat /usr/share/nginx/html/index.html > /var/www/html/index.html

# Default PHP-FPM on Nginx configuration
#-----------------------------------------------------------------------------------------
find /etc/nginx/stubs/ -type f -exec sed -i "s/php.*.-fpm/php\/php${default_php}-fpm/g" {} +
sed -i "s/php.*.-fpm/php\/php${default_php}-fpm/g" /etc/nginx/conf.d/default.conf
systemctl restart nginx

# Nginx Amplify
#-----------------------------------------------------------------------------------------
if [ -f "$PWD/stackup.ini" ]; then
    [[ $(cat "$PWD/stackup.ini" | grep -c "amplify_install") -eq 1 ]] && amplify_install=$(crudini --get $PWD/stackup.ini '' 'amplify_install')
    [[ -z "$amplify_install" ]] && read -ep "Do you want to use Nginx Amplify ?          y/n : " amplify_install
fi

if [[ "${amplify_install,,}" =~ ^(yes|y)$ ]] ; then
    if [ -f "$PWD/stackup.ini" ]; then
        [[ $(cat "$PWD/stackup.ini" | grep -c "amplify_key") -eq 1 ]] && amplify_key=$(crudini --get $PWD/stackup.ini '' 'amplify_key')
        [[ -z "$amplify_key" ]] && read -ep "Nginx Amplify Key                               : " amplify_key
    fi

    # Install and configure Nginx Amplify
    API_KEY=$amplify_key bash <(curl -sLo- https://git.io/fNWVx)
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
    systemctl restart amplify-agent
fi

# Crontab for renewing LetsEncrypt certificates
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Configuring cron for renewing certificates...${NC}"
echo "01 01 01 */3 * /usr/local/bin/ssl-renew >/var/log/ssl-renew.log" > /tmp/ssl_renew
crontab /tmp/ssl_renew ; rm /tmp/ssl_renew
