#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

# Determine root directory
[ -z $ROOTDIR ] && PWD=$(dirname `dirname $(dirname $(readlink -f $0))`) || PWD=$ROOTDIR

# Common global variables
source "$PWD/common.sh"

#-----------------------------------------------------------------------------------------
msgSuccess "\n--- Installing Nginx Mainline"
#-----------------------------------------------------------------------------------------
! [[ -z $(which nginx) ]] && msgError "Already installed..." && exit 1

# Install packages
#-----------------------------------------------------------------------------------------
curl -sS http://nginx.org/keys/nginx_signing.key | apt-key add - &>${logInstall}
cat > /etc/apt/sources.list.d/nginx.list <<EOF
deb [arch=amd64] https://nginx.org/packages/mainline/debian `lsb_release -cs` nginx
EOF

pkgUpgrade
apt -yq install {libpng,libssl,libffi,libexpat1}-dev libarchive-tools libimage-exiftool-perl \
libaugeas0 haveged gamin nginx augeas-lenses openssl python-dev python-virtualenv &>${logInstall}

# Download latest certbot
msgInfo "\nDownloading certbot and trusted certificates..."
curl -L# https://dl.eff.org/certbot-auto -o /usr/bin/certbot ; chmod a+x /usr/bin/certbot
curl -L# https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt -o /etc/ssl/certs/chain.pem
curl -L# https://2ton.com.au/dhparam/4096 -o /etc/ssl/certs/dhparam-4096.pem
curl -L# https://2ton.com.au/dhparam/2048 -o /etc/ssl/certs/dhparam-2048.pem

# Configure packages
#-----------------------------------------------------------------------------------------
msgSuccess "\n--- Configuring Nginx Mainline"
ip6Check=$(crudini --get /etc/sysctl.conf '' 'net.ipv6.conf.all.disable_ipv6')

systemctl enable --now haveged &>${logInstall}
rm -fr /etc/nginx/ ; cp -r $PWD/config/nginx/ /etc/
sed -i "s|\("^worker_processes" * *\).*|\1$(nproc --all);|" /etc/nginx/nginx.conf
sed -i "s|\("^worker_connections" * *\).*|\1$(ulimit -n);|" /etc/nginx/nginx.conf
sed -i "s/HOSTNAME/$(hostname -f)/"          /etc/nginx/conf.d/default.conf
sed -i "s/IPADDRESS/$(curl -s ifconfig.me)/" /etc/nginx/conf.d/default.conf

mkdir -p /etc/nginx/vhost.d /srv/web /var/www/html
cat /etc/nginx/stubs/default.html > /usr/share/nginx/html/index.html
cat /etc/nginx/stubs/error404.html > /usr/share/nginx/html/404.html
chown -R webmaster: /var/www && chmod -R 0775 /var/www
chown -R root:root /etc/nginx
systemctl restart nginx

# SSL certifiacte for default vhost
#-----------------------------------------------------------------------------------------
setupNginxDefaultHttps() {
    # Update nginxconfiguration
    # mv /etc/nginx/conf.d/force-https.conf{-disable,}
    cat /etc/nginx/vhost.tpl/default-ssl.conf > /etc/nginx/conf.d/default.conf
    sed -i "s/HOSTNAME/$(hostname -f)/"          /etc/nginx/conf.d/default.conf
    sed -i "s/IPADDRESS/$(curl -s ifconfig.me)/" /etc/nginx/conf.d/default.conf
    systemctl restart nginx
}

if [ -d "/etc/letsencrypt/live/$(hostname -f)" ]; then
    setupNginxDefaultHttps
elif [ ! -d "/etc/letsencrypt/live/$(hostname -f)" ]; then
    read -ep "Generate ssl cert for default vhost?        y/n : " -i "n" answer
    if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
        systemctl stop nginx
        certbot certonly --standalone --agree-tos --register-unsafely-without-email \
            --no-bootstrap --rsa-key-size 4096 --preferred-challenges http -d "$(hostname -f)"
        setupNginxDefaultHttps
    fi
fi

# Use IPv6 or not?
#-----------------------------------------------------------------------------------------
if [[ $ip6Check -ne 1 ]]; then
    sed -i "s/# include listen_ipv6/include listen_ipv6/" /etc/nginx/conf.d/default.conf
    sed -i "s/# listen/listen/" /etc/nginx/conf.d/default.conf
    systemctl restart nginx
fi

# Crontab for renewing LetsEncrypt certificates
#-----------------------------------------------------------------------------------------
msgInfo "Configuring cron for renewing certificates..."
echo "01 01 01 */3 * /usr/local/bin/ssl-renew >/var/log/ssl-renew.log" > /tmp/ssl_renew
crontab /tmp/ssl_renew ; rm /tmp/ssl_renew
