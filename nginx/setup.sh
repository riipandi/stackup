#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

PWD=$(dirname "$(readlink -f "$0")")
PARENT=$(dirname "$PWD")


# Set Nginx repository
#-----------------------------------------------------------------------------------------
echo "deb http://ppa.launchpad.net/ondrej/nginx/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/nginx.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com E5267A6C && apt update

# Install packages
#-----------------------------------------------------------------------------------------
apt full-upgrade -y ; apt install -y {libpng,libssl,libffi,libexpat1}-dev libarchive-tools \
libimage-exiftool-perl libaugeas0 openssl haveged gamin nginx augeas-lenses

# Extra packages
#-----------------------------------------------------------------------------------------
echo -e "\nDownloading extra utilities..."
curl -L# "https://git.io/vN3Ff" -o /usr/local/bin/wp
curl -L# "https://git.io/fAFyN" -o /usr/local/bin/phpcs
curl -L# "https://git.io/fAFyb" -o /usr/local/bin/phpcbf
curl -L# "https://cs.sensiolabs.org/download/php-cs-fixer-v2.phar" -o /usr/local/bin/php-cs-fixer
chmod +x /usr/local/bin/* ; chown root: /usr/local/bin/*

echo -e "\nDownloading Diffie-Hellman Parameter..."
curl -L# https://2ton.com.au/dhparam/2048 -o /etc/ssl/certs/dhparam-2048.pem
curl -L# https://2ton.com.au/dhparam/3072 -o /etc/ssl/certs/dhparam-3072.pem
curl -L# https://2ton.com.au/dhparam/4096 -o /etc/ssl/certs/dhparam-4096.pem

# Download latest certbot
echo -e "Downloading certbot and trusted certificates..."
wget https://dl.eff.org/certbot-auto -qO /usr/bin/certbot ; chmod a+x /usr/bin/certbot
curl -L# https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt -o /etc/ssl/certs/chain.pem

# Configure Nginx
#-----------------------------------------------------------------------------------------
systemctl enable --now haveged ; systemctl stop nginx
mkdir -p /var/www ; rm -fr /etc/nginx/*
cp -r $PWD/config/* /etc/nginx/.
chown -R root: /etc/nginx

# Adjusting nginx configuration
sed -i "s|\("^worker_processes" * *\).*|\1$(nproc --all);|" /etc/nginx/nginx.conf
sed -i "s|\("^worker_connections" * *\).*|\1$(ulimit -n);|" /etc/nginx/nginx.conf

sed -i "s/HOSTNAME/$(hostname -f)/"          /etc/nginx/vhost.d/default.conf
sed -i "s/IPADDRESS/$(curl -s ifconfig.me)/" /etc/nginx/vhost.d/default.conf

# Default web page
cp /etc/nginx/manifest/default.php /var/www/index.php
chown -R www-data: /var/www ; chmod -R 0775 /var/www

# Custom error page for nginx
echo "Error 404" > /usr/share/nginx/html/404.html
echo "Error 50x" > /usr/share/nginx/html/50x.html

# SSL certifiacte for default vhost
#-----------------------------------------------------------------------------------------
if [[ ! -d "/etc/letsencrypt/live/$(hostname -f)" ]]; then
  certbot certonly --standalone --agree-tos --rsa-key-size 4096 \
    --register-unsafely-without-email --preferred-challenges http \
    -d "$(hostname -f)"
fi
systemctl restart nginx


# Get parameter
#-----------------------------------------------------------------------------------------
AMPLIFY_INSTALL=`crudini --get $PARENT/config.ini nginx amplify`
AMPLIFY_API_KEY=`crudini --get $PARENT/config.ini nginx api_key`

DB_ROOT_USER="root"
DB_ROOT_PASS=`crudini --get $ROOT/config.ini mysql root_pass`
DB_BIND_ADDR=`crudini --get $ROOT/config.ini mysql bind_address`
DB_SOCKET_PATH="/var/run/mysqld/mysqld.sock"

if [ $AMPLIFY_INSTALL == "yes" ] ; then

    # Install Nginx Amplify
    API_KEY=$AMPLIFY_API_KEY bash <(curl -sLo- https://git.io/fNWVx)

    # Configure Nginx Amplify
    crudini --set /etc/amplify-agent/agent.conf 'listener_syslog-default' '​address' '127.0.0.1:13579'

    crudini --set /etc/amplify-agent/agent.conf 'extensions' 'mysql' 'True'
    crudini --set /etc/amplify-agent/agent.conf 'mysql' 'unix_socket' $DB_SOCKET_PATH
    crudini --set /etc/amplify-agent/agent.conf 'mysql' 'password'    $DB_ROOT_PASS
    crudini --set /etc/amplify-agent/agent.conf 'mysql' 'user'        $DB_ROOT_USER

    crudini --set /etc/amplify-agent/agent.conf 'credentials' 'hostname' `hostname -f`
    crudini --set /etc/amplify-agent/agent.conf 'extensions'  'phpfpm' 'True'

    mv /etc/nginx/conf.d/stub_status.{conf-disable,conf}

    systemctl restart amplify-agent
fi
