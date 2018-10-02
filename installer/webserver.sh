#!/bin/bash

PWD=$(dirname "$(readlink -f "$0")")
PARENT=$(dirname $PWD)

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

#-----------------------------------------------------------------------------------------
# 00 - Setup Repositories
#-----------------------------------------------------------------------------------------


#-----------------------------------------------------------------------------------------
# 01 - Installing Packages
#-----------------------------------------------------------------------------------------
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_ROOT_PASS"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_ROOT_PASS"
apt -y install nano gcc make cmake build-essential git whois nscd dh-autoreconf \
binutils dnsutils resolvconf ftp zip unzip bsdtar rsync screen ca-certificates \
software-properties-common debconf-utils screenfetch haveged nmap nikto sqlite3 \
speedtest-cli xmlstarlet {libpng,libssl,libffi}-dev libarchive-tools gamin mcrypt \
gettext imagemagick libimage-exiftool-perl optipng jpegoptim php-{imagick,pear} \
php7.2 php7.2-{common,cli,cgi,fpm,mbstring,opcache,gmp,readlinezip,sqlite3,intl} \
php7.2-{bcmath,json,xml,xmlrpc,mysql,pgsql,imap,gd,curl,zip} nginx composer nodejs \
letsencrypt mariadb-{server,client}

# Additional PHP
apt install php5.6 php5.6-{common,cli,cgi,fpm,mbstring,opcache,gmp,xmlrpc,readline} \
php5.6-{bcmath,zip,sqlite3,intl,json,xml,imap,gd,curl,zip,mysql,pgsql}

# Python Stack
apt -y install {python,python3}-{dev,virtualenv,pip,setuptools,gunicorn,mysqldb} \
supervisor {python,python3}-{flaskext.wtf,flask-{migrate,restful,sqlalchemy,bcrypt}} \
python-{m2crypto,configparser} gunicorn gunicorn3

# Extra Packages
curl -L# https://git.io/vN3Ff -o /usr/bin/wp ; chmod a+x /usr/bin/wp
curl -L# https://git.io/fAFyN -o /usr/bin/phpcs ; chmod a+x /usr/bin/phpcs
curl -L# https://git.io/fAFyb -o /usr/bin/phpcbf ; chmod a+x /usr/bin/phpcbf
curl -L# https://cs.sensiolabs.org/download/php-cs-fixer-v2.phar -o /usr/bin/php-cs-fixer
chmod a+x /usr/bin/php-cs-fixer

#-----------------------------------------------------------------------------------------
# 02 - Configuring MySQL
#-----------------------------------------------------------------------------------------
sed -i "s/skip-external-locking//" /etc/mysql/my.cnf
mysql -uroot -p"$DB_ROOT_PASS" -e "UPDATE mysql.user SET plugin='' WHERE User='root';"
crudini --set /etc/mysql/conf.d/mariadb.cnf 'mysqld' 'bind-address' $DB_BIND_ADDR
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'host'     $DB_BIND_ADDR
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'password' $DB_ROOT_PASS
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'user'     'root'


#-----------------------------------------------------------------------------------------
# 03 - Configuring PHP-FPM
#-----------------------------------------------------------------------------------------
crudini --set /etc/php/5.6/fpm/php-fpm.conf  'www' 'listen' '/var/run/php/php56-fpm.sock'
crudini --set /etc/php/7.2/fpm/php-fpm.conf  'www' 'listen' '/var/run/php/php72-fpm.sock'
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "upload_max_filesize"     "32M"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "max_execution_time"      "300"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "max_input_time"          "300"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "post_max_size"           "16M"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "display_errors"          "Off"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "cgi.fix_pathinfo"        "0"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "memory_limit"            "1536M"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "expose_php"              "Off"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm"                      "ondemand"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.max_children"         "32"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.start_servers"        "2"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.min_spare_servers"    "4"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.max_spare_servers"    "8"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.max_requests"         "256"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.process_idle_timeout" "10s"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.status_path" "/status"' {} \;
phpenmod curl opcache imagick fileinfo
systemctl restart php{5.6,7.2}-fpm

#-----------------------------------------------------------------------------------------
# 04 - Configuring Nginx
#-----------------------------------------------------------------------------------------
mkdir -p /var/www ; systemctl enable --now haveged ; systemctl stop nginx

curl -L# https://2ton.com.au/dhparam/4096 -o /etc/ssl/certs/dhparam.pem
curl -L# https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt -o /etc/ssl/certs/chain.pem
certbot certonly --standalone --rsa-key-size 4096 --agree-tos --register-unsafely-without-email -d "$(hostname -f)"

rm -fr /etc/nginx ; cp -r $PWD/config/nginx /etc ; chown -R root: /etc/nginx
cp /etc/nginx/manifest/default-hello.tpl /var/www/index.php
chown -R www-data: /var/www
chmod -R 775 /var/www

sed -i "s|\("^worker_processes" * *\).*|\1$(nproc --all);|" /etc/nginx/nginx.conf
sed -i "s|\("^worker_connections" * *\).*|\1$(ulimit -n);|" /etc/nginx/nginx.conf
sed -i "s/IPADDRESS/$(curl -s v4.ifconfig.co)/" /etc/nginx/conf.d/default.conf
sed -i "s/HOSTNAME/$(hostname -f)/"  /etc/nginx/conf.d/default.conf
sed -i "s/HOSTNAME/$(hostname -f)/"  /etc/nginx/server.d/server.conf
systemctl restart nginx

#-----------------------------------------------------------------------------------------
# 05 - Configuring Nginx Amplify
#-----------------------------------------------------------------------------------------
if [ ! -f /etc/apt/sources.list.d/nginx-amplify.list ]; then
  API_KEY=$NGX_AMPLIFY_KEY bash <(curl -sLo- https://git.io/fNWVx)
  crudini --set /etc/amplify-agent/agent.conf 'listener_syslog-default' '​address' '127.0.0.1:13579'
  crudini --set /etc/amplify-agent/agent.conf 'mysql' 'unix_socket' '/var/run/mysqld/mysqld.sock'
  crudini --set /etc/amplify-agent/agent.conf 'mysql' 'user' 'root'
  crudini --set /etc/amplify-agent/agent.conf 'mysql' 'password' $DB_ROOT_PASS
  crudini --set /etc/amplify-agent/agent.conf 'credentials' 'hostname' `hostname -f`
  crudini --set /etc/amplify-agent/agent.conf 'extensions' 'phpfpm' 'True'
  crudini --set /etc/amplify-agent/agent.conf 'extensions' 'mysql' 'True'
  systemctl restart amplify-agent
fi


#-----------------------------------------------------------------------------------------
# 06 - Installing phpMyAdmin
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