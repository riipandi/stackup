#!/usr/bin/env bash

PARENT=$(dirname "$(dirname `readlink -f $0`)")

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

echo "deb https://nginx.org/packages/debian/ `lsb_release -cs` nginx" > /etc/apt/sources.list.d/nginx.list
curl -sS https://nginx.org/keys/nginx_signing.key | apt-key add -

apt update ; apt -yqq install haveged nmap nikto xmlstarlet {libpng,libssl,libffi}-dev \
libarchive-tools libimage-exiftool-perl speedtest-cli gamin mcrypt imagemagick \
gettext optipng jpegoptim sqlite3 nginx augeas-lenses libaugeas0 libexpat1-dev \
libpython-dev libpython2.7 libpython2.7-dev virtualenv python-dev python-pip-whl \
python-virtualenv python2.7-dev python3-virtualenv openssl

# Latest Certbot
echo -e "Downloading certbot and trusted certificates..."
wget https://dl.eff.org/certbot-auto -O /usr/bin/certbot ; chmod a+x /usr/bin/certbot
curl -L# https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt -o /etc/ssl/certs/chain.pem

systemctl enable --now haveged
systemctl stop nginx

mkdir -p /var/www
rm -fr /etc/nginx/*
cp -r $ROOT/nginx/config/* /etc/nginx/.
chown -R root: /etc/nginx

sed -i "s|\("^worker_processes" * *\).*|\1$(nproc --all);|" /etc/nginx/nginx.conf
sed -i "s|\("^worker_connections" * *\).*|\1$(ulimit -n);|" /etc/nginx/nginx.conf

sed -i "s/IPADDRESS/$(curl -s ifconfig.me)/" /etc/nginx/conf.d/default.conf
sed -i "s/HOSTNAME/$(hostname -f)/"          /etc/nginx/conf.d/default.conf
sed -i "s/HOSTNAME/$(hostname -f)/"          /etc/nginx/server.d/server.conf

cp /etc/nginx/manifest/default.tpl /var/www/index.php
chown -R www-data: /var/www
chmod -R 0775 /var/www

##
# Generate SSL certificates for default vhost
# certbot revoke --cert-path /etc/letsencrypt/live/$(hostname -f)/fullchain.pem
##
if [[ ! -d "/etc/letsencrypt/live/$(hostname -f)" ]]; then
  certbot certonly --standalone --agree-tos --rsa-key-size 3072 \
    --register-unsafely-without-email --preferred-challenges http \
    -d "$(hostname -f)"
fi

systemctl restart nginx
