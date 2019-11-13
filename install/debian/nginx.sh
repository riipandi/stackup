#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
NOCOLOR='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;33m'
BLUE='\033[0;34m'
CURRENT=$(dirname $(readlink -f $0))
[ -z $ROOTDIR ] && PWD=$(dirname `dirname $CURRENT`) || PWD=$ROOTDIR

#-----------------------------------------------------------------------------------------
echo -e "\n${BLUE}Installing Nginx...${NOCOLOR}"
#-----------------------------------------------------------------------------------------
! [[ -z $(which nginx) ]] && echo -e "${BLUE}Already installed...${NOCOLOR}" && exit 1

# Install packages
#-----------------------------------------------------------------------------------------
curl -sS http://nginx.org/keys/nginx_signing.key | apt-key add - &>/dev/null
cat > /etc/apt/sources.list.d/nginx.list <<EOF
deb [arch=amd64] https://nginx.org/packages/mainline/debian `lsb_release -cs` nginx
EOF

apt update -qq ; apt full-upgrade -yqq
apt -yqq install {libpng,libssl,libffi,libexpat1}-dev libarchive-tools libimage-exiftool-perl \
libaugeas0 haveged gamin nginx augeas-lenses openssl python-dev python-virtualenv

# Download latest certbot
echo -e "\n${BLUE}Downloading certbot and trusted certificates...${NOCOLOR}"
curl -L# https://dl.eff.org/certbot-auto -o /usr/bin/certbot ; chmod a+x /usr/bin/certbot
curl -L# https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt -o /etc/ssl/certs/chain.pem
curl -L# https://2ton.com.au/dhparam/4096 -o /etc/ssl/certs/dhparam-4096.pem
curl -L# https://2ton.com.au/dhparam/2048 -o /etc/ssl/certs/dhparam-2048.pem

# Configure packages
#-----------------------------------------------------------------------------------------
systemctl enable --now haveged && rm -fr /etc/nginx/ ; cp -r $PWD/config/nginx/ /etc/
sed -i "s|\("^worker_processes" * *\).*|\1$(nproc --all);|" /etc/nginx/nginx.conf
sed -i "s|\("^worker_connections" * *\).*|\1$(ulimit -n);|" /etc/nginx/nginx.conf
sed -i "s/HOSTNAME/$(hostname -f)/"          /etc/nginx/conf.d/default.conf
sed -i "s/IPADDRESS/$(curl -s ifconfig.me)/" /etc/nginx/conf.d/default.conf

mkdir -p /etc/nginx/vhost.d /var/www/html /srv/web
cat /etc/nginx/stubs/default.html > /usr/share/nginx/html/index.html
chown -R webmaster: /var/www && chmod -R 0775 /var/www
chown -R root:root /etc/nginx
systemctl restart nginx

# SSL certifiacte for default vhost
#-----------------------------------------------------------------------------------------
setupNginxDefaultHttps() {
    # Update nginxconfiguration
    # mv /etc/nginx/conf.d/force-https.conf{-disable,}
    cat /etc/nginx/stubs/vhost-default.conf > /etc/nginx/conf.d/default.conf
    sed -i "s/HOSTNAME/$(hostname -f)/"          /etc/nginx/conf.d/default.conf
    sed -i "s/IPADDRESS/$(curl -s ifconfig.me)/" /etc/nginx/conf.d/default.conf
    systemctl restart nginx
}

if [ -d "/etc/letsencrypt/live/$(hostname -f)" ]; then
    setupNginxDefaultHttps
elif [ ! -d "/etc/letsencrypt/live/$(hostname -f)" ]; then
    read -ep "Generate ssl cert for default vhost ?       y/n : " -i "n" answer
    if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
        systemctl stop nginx
        certbot certonly --standalone --agree-tos --register-unsafely-without-email \
            --rsa-key-size 4096 --preferred-challenges http -d "$(hostname -f)"
        setupNginxDefaultHttps
    fi
fi

# Crontab for renewing LetsEncrypt certificates
#-----------------------------------------------------------------------------------------
echo -e "\n${BLUE}Configuring cron for renewing certificates...${NOCOLOR}"
echo "01 01 01 */3 * /usr/local/bin/ssl-renew >/var/log/ssl-renew.log" > /tmp/ssl_renew
crontab /tmp/ssl_renew ; rm /tmp/ssl_renew

# Default PHP-FPM on Nginx configuration
#-----------------------------------------------------------------------------------------
# find /etc/nginx/stubs/ -type f -exec sed -i "s/php.*.-fpm/php\/php${default_php}-fpm/g" {} +
# sed -i "s/php.*.-fpm/php\/php${default_php}-fpm/g" /etc/nginx/conf.d/default.conf
# systemctl restart nginx
