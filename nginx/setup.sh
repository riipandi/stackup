#!/usr/bin/env bash

PARENT=$(dirname "$(dirname `readlink -f $0`)")

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

echo "deb https://nginx.org/packages/debian/ `lsb_release -cs` nginx" > /etc/apt/sources.list.d/nginx.list
curl -sS https://nginx.org/keys/nginx_signing.key | apt-key add -

apt update ; apt -yqq install haveged nmap nikto xmlstarlet {libpng,libssl,libffi}-dev \
libarchive-tools libimage-exiftool-perl speedtest-cli gamin mcrypt imagemagick \
gettext optipng jpegoptim sqlite3 nginx augeas-lenses libaugeas0 libexpat1-dev \
libpython-dev libpython2.7 libpython2.7-dev virtualenv python-virtualenv python-dev \
python-pip python-pip-whl python2.7-dev python3-virtualenv openssl

# Latest Certbot
echo -e "Downloading certbot and trusted certificates..."
wget https://dl.eff.org/certbot-auto -qO /usr/bin/certbot ; chmod a+x /usr/bin/certbot
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
sed -i "s/IPADDRESS/$(curl -s ifconfig.me)/" /etc/nginx/nginx.conf
sed -i "s/HOSTNAME/$(hostname -f)/"          /etc/nginx/nginx.conf
sed -i "s/HOSTNAME/$(hostname -f)/"          /etc/nginx/conf.d/default.conf
sed -i "s/HOSTNAME/$(hostname -f)/"          /etc/nginx/conf.d/default.conf
sed -i "s/HOSTNAME/$(hostname -f)/"          /etc/nginx/server.d/server.conf

# Default web page
cp /etc/nginx/manifest/default.tpl /var/www/index.php
cp -r /etc/nginx/_errors/ /var/www/
chown -R www-data: /var/www
chmod -R 0775 /var/www

## Setup certbot DNS Plugin
## https://www.codementor.io/slavko/generating-letsencrypt-wildcard-certificate-with-certbot-hts4aee8u
# pip install certbot-dns-cloudflare certbot-dns-digitalocean certbot-dns-google certbot-dns-route53

# mkdir -p /etc/letsencrypt
# cat > /etc/letsencrypt/cli.ini <<EOF
# dns-cloudflare-credentials = /etc/letsencrypt/dnscredentials.ini
# server = https://acme-v02.api.letsencrypt.org/directory
# EOF

# touch /etc/letsencrypt/dnscredentials.ini ; chmod 600 $_
# cat > /etc/letsencrypt/dnscloudflare.ini <<EOF
# dns_cloudflare_api_key = yourcloudflarekey
# dns_cloudflare_email = yourcloudflarelogin
# EOF

##
# Generate SSL certificates for default vhost
# certbot revoke --cert-path /etc/letsencrypt/live/$(hostname -f)/fullchain.pem
##
if [[ ! -d "/etc/letsencrypt/live/$(hostname -f)" ]]; then
  certbot certonly --standalone --agree-tos --rsa-key-size 4096 \
    --register-unsafely-without-email --preferred-challenges http \
    -d "$(hostname -f)"
fi

systemctl restart nginx

# Generate Public Key Pinning Extension for HTTP (HPKP):
# cat /etc/ssl/certs/chain.pem | openssl dgst -sha256 -binary | base64

# hpkp_value=`openssl x509 -pubkey < /etc/letsencrypt/archive/$(hostname -f)/cert1.pem | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64`
# sed -i "s/HPKP_VALUE/$hpkp_value/" /etc/nginx/nginx.conf
