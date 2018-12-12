#!/usr/bin/env bash

CURRENT=$(dirname "$(readlink -f "$0")")
PARENT=$(dirname "$CURRENT")

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

function getbin(){
  curl -L# $1 -o $2
  chmod a+x $2
}

#-----------------------------------------------------------------------------------------
# Setup Repositories
#-----------------------------------------------------------------------------------------
echo "deb https://nginx.org/packages/debian/ `lsb_release -cs` nginx" > /etc/apt/sources.list.d/nginx.list
curl -sS https://nginx.org/keys/nginx_signing.key | apt-key add -

echo "deb https://packages.sury.xyz/php/ `lsb_release -cs` main" > /etc/apt/sources.list.d/sury-php.list
curl -sS https://packages.sury.xyz/php/apt.gpg    | apt-key add -

#-----------------------------------------------------------------------------------------
# Installing Packages
#-----------------------------------------------------------------------------------------
apt update ; apt -y install haveged nmap nikto xmlstarlet {libpng,libssl,libffi}-dev \
libarchive-tools libimage-exiftool-perl speedtest-cli gamin mcrypt imagemagick \
gettext optipng jpegoptim sqlite3 php-{imagick,pear} php7.3 php7.3-{common,cli,cgi} \
php7.3-{fpm,bcmath,mbstring,opcache,json,gmp,readline,zip,sqlite3,intl,xml,xmlrpc} \
php7.3-{curl,zip,mysql,pgsql,imap,gd} nginx composer

# Extra Packages
getbin https://dl.eff.org/certbot-auto /usr/bin/certbot
getbin https://git.io/vN3Ff /usr/bin/wp
getbin https://git.io/fAFyN /usr/bin/phpcs
getbin https://git.io/fAFyb /usr/bin/phpcbf
getbin https://cs.sensiolabs.org/download/php-cs-fixer-v2.phar /usr/bin/php-cs-fixer

# Configure php-fpm
crudini --set /etc/php/7.3/fpm/php-fpm.conf  'www' 'listen' '/var/run/php/php73-fpm.sock'
phpenmod curl opcache imagick fileinfo && systemctl restart php7.3-fpm

# Configure PHP-FPM
echo -e "Configuring PHP-FPM"
source $CURRENT/phpcfg.sh

#-----------------------------------------------------------------------------------------
# Configure Nginx
#-----------------------------------------------------------------------------------------
mkdir -p /var/www ; systemctl enable --now haveged ; systemctl stop nginx

curl -L# https://2ton.com.au/dhparam/4096 -o /etc/ssl/certs/dhparam.pem
curl -L# https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt \
  -o /etc/ssl/certs/chain.pem

# Generate SSL certificates for default vhost
certbot certonly --standalone --agree-tos --rsa-key-size 4096 \
  --register-unsafely-without-email --preferred-challenges http \
  -d "$(hostname -f)"

rm -fr /etc/nginx
cp -r $PARENT/config/nginx /etc
cp /etc/nginx/manifest/default.tpl /var/www/index.php
chown -R root: /etc/nginx
chown -R www-data: /var/www
chmod -R 775 /var/www

sed -i "s|\("^worker_processes" * *\).*|\1$(nproc --all);|" /etc/nginx/nginx.conf
sed -i "s|\("^worker_connections" * *\).*|\1$(ulimit -n);|" /etc/nginx/nginx.conf
sed -i "s/IPADDRESS/$(curl -s v4.ifconfig.co)/" /etc/nginx/conf.d/default.conf
sed -i "s/HOSTNAME/$(hostname -f)/"  /etc/nginx/conf.d/default.conf
sed -i "s/HOSTNAME/$(hostname -f)/"  /etc/nginx/server.d/server.conf
systemctl restart nginx

#-----------------------------------------------------------------------------------------
# Installing phpMyAdmin
#-----------------------------------------------------------------------------------------
PMA_DIR="/var/www/myadmin"

if [ ! -d $PMA_DIR ]; then
curl -fsSL https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-english.zip | bsdtar -xvf-
mv $PWD/phpMyAdmin*-english $PMA_DIR

chmod -R 755 $PMA_DIR
find $PMA_DIR/. -type d -exec chmod 0777 {} \;
find $PMA_DIR/. -type f -exec chmod 0644 {} \;
chown -R www-data: $PMA_DIR

cat > $PMA_DIR/config.inc.php <<EOF
<?php
\$cfg['blowfish_secret'] = '`openssl rand -hex 16`';
\$i = 0; \$i++;
\$cfg['Servers'][\$i]['auth_type']       = 'cookie';
\$cfg['Servers'][\$i]['host']            = '127.0.0.1';
\$cfg['Servers'][\$i]['connect_type']    = 'tcp';
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;
\$cfg['Servers'][\$i]['hide_db']         = '^(information_schema|performance_schema|mysql|phpmyadmin|sys)\$';
\$cfg['UploadDir']                       = '';
\$cfg['SaveDir']                         = '';
\$cfg['MaxRows']                         = 100;
\$cfg['SendErrorReports']                = 'never';
\$cfg['ShowDatabasesNavigationAsTree']   = false;
EOF
fi