#!/bin/bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

PWD=$(dirname "$(readlink -f "$0")")

PMA_DIR="/var/www/myadmin"

# Check configuration file
if [ ! -f $PWD/envar ]; then

cat > $PWD/envar <<EOF
SSH_PORT="22"
TIMEZONE="Asia/Jakarta"

DB_ROOT_PASS="xxxxxxx"
DB_BIND_ADDR="127.0.0.1"

CP_DB_NAME="xxxxxxx"
CP_DB_PASS="xxxxxxx"

AMPLIFY_KEY="xxxxxxx"

TELEGRAM_USERID="xxxxxxx"
TELEGRAM_BOTKEY="xxxxxxx"

SETUP_IMAPSYNC="no"
EOF

    echo -e "Please edit envar file then run this script again!"
    exit 1
fi

echo -e "" ; read -p "Press enter to continue" ; echo -e "\n"

source $PWD/envar


echo '- Adding LEMP repository list and the keys'
#-----------------------------------------------------------------------------------------
# 00 - Setup Repositories
#-----------------------------------------------------------------------------------------
source $PWD/setrepo.sh ; apt update ; apt full-upgrade -y ; apt autoremove -y

# Resolver
rm -f /etc/resolv.conf
echo 'nameserver 209.244.0.3' >  /etc/resolv.conf
echo 'nameserver 209.244.0.4' >> /etc/resolv.conf


echo '- Installing packages'
#-----------------------------------------------------------------------------------------
# 01 - Installing Packages
#-----------------------------------------------------------------------------------------
debconf-set-selections <<< "iptables-persistent iptables-persistent/autosave_v4 boolean true"
debconf-set-selections <<< "iptables-persistent iptables-persistent/autosave_v6 boolean true"
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_ROOT_PASS"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_ROOT_PASS"
debconf-set-selections <<< "pdns-backend-mysql pdns-backend-mysql/dbconfig-install boolean false"

apt -y install nano curl crudini lsof ntp gcc make cmake build-essential git whois \
ntp nscd dh-autoreconf binutils dnsutils resolvconf ftp zip unzip bsdtar rsync nmap \
screen ca-certificates software-properties-common debconf-utils screenfetch nikto \
elinks pwgen speedtest-cli haveged xmlstarlet {libpng,libssl,libffi}-dev imagemagick \
libimage-exiftool-perl libarchive-tools sqlite3 mcrypt gamin gettext php-{imagick,pear} \
php7.2 php7.2-{common,cli,cgi,fpm,mbstring,opcache,gmp,xmlrpc,readline,mysql,pgsql} \
php7.2-{bcmath,zip,sqlite3,intl,json,xml,imap,gd,curl,zip} composer nginx nodejs \
letsencrypt optipng jpegoptim mariadb-{server,client} pdns-{server,backend-mysql} \
proftpd-mod-mysql iptables iptables-persistent postgresql-{10,client-10}

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
curl -L# https://semut.org/gdrive -o /usr/bin/gdrive ; chmod a+x /usr/bin/gdrive
curl -L# https://cs.sensiolabs.org/download/php-cs-fixer-v2.phar -o /usr/bin/php-cs-fixer
chmod a+x /usr/bin/php-cs-fixer

echo '- Basic Configuration'
#-----------------------------------------------------------------------------------------
# 02 - Basic Configuration
#-----------------------------------------------------------------------------------------
perl -pi -e 's#(.*sudo.*ALL=)(.*)#${1}(ALL) NOPASSWD:ALL#' /etc/sudoers
timedatectl set-timezone $TIMEZONE
ntpdate -u 0.asia.pool.ntp.org
mkdir -p /var/www

# Disable IPv6 + Swapfile
crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.all.disable_ipv6'     '1'
crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.default.disable_ipv6' '1'
crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.lo.disable_ipv6'      '1'
crudini --set /etc/sysctl.conf '' 'net.ipv4.ip_forward'   '1'
crudini --set /etc/sysctl.conf '' 'vm.vfs_cache_pressure' '50'
crudini --set /etc/sysctl.conf '' 'vm.swappiness' '10'

# SSH Server
sed -i "s|\("^PubkeyAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ClientAliveInterval" * *\).*|\1600|" /etc/ssh/sshd_config
sed -i "s|\("^AllowTcpForwarding" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ClientAliveCountMax" * *\).*|\13|" /etc/ssh/sshd_config
sed -i "s|\("^ListenAddress" * *\).*|\10.0.0.0|" /etc/ssh/sshd_config
sed -i "s|\("^PermitRootLogin" * *\).*|\1no|" /etc/ssh/sshd_config
sed -i "s|\("^PermitTunnel" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^StrictModes" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s/[#]*ListenAddress/ListenAddress/" /etc/ssh/sshd_config
sed -i "s/[#]*Port [0-9]*/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i "s/ListenAddress :://" /etc/ssh/sshd_config
systemctl restart ssh

echo '- Configure MariaDB'
#-----------------------------------------------------------------------------------------
# 03 - Configure MariaDB
#-----------------------------------------------------------------------------------------
sed -i "s/skip-external-locking//" /etc/mysql/my.cnf
mysql -uroot -p"$DB_ROOT_PASS" -e "UPDATE mysql.user SET plugin='' WHERE User='root';"
crudini --set /etc/mysql/conf.d/mariadb.cnf 'mysqld' 'bind-address' $DB_BIND_ADDR
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'host'     $DB_BIND_ADDR
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'password' $DB_ROOT_PASS
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'user'     'root'


echo '- Configure PostgreSQL'
#-----------------------------------------------------------------------------------------
# 04 - Configure PostgreSQL
#-----------------------------------------------------------------------------------------
sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$DB_ROOT_PASS'"


echo '- Configure PHP-FPM'
#-----------------------------------------------------------------------------------------
# 05 - COnfigure PHP-FPM
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


echo '- Configure Nginx'
#-----------------------------------------------------------------------------------------
# 06 - Configure Nginx
#-----------------------------------------------------------------------------------------
systemctl enable --now haveged ; systemctl stop nginx

curl -L# https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt -o /etc/ssl/certs/chain.pem
curl -L# https://2ton.com.au/dhparam/4096 -o /etc/ssl/certs/dhparam.pem

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


echo '- Configure Nginx Amplify'
#-----------------------------------------------------------------------------------------
# 07 - Configure Nginx Amplify
#-----------------------------------------------------------------------------------------
if [ ! -f /etc/apt/sources.list.d/nginx-amplify.list ]; then
  API_KEY=$AMPLIFY_KEY bash <(curl -sLo- https://git.io/fNWVx)
  crudini --set /etc/amplify-agent/agent.conf 'listener_syslog-default' '​address' '127.0.0.1:13579'
  crudini --set /etc/amplify-agent/agent.conf 'mysql' 'unix_socket' '/var/run/mysqld/mysqld.sock'
  crudini --set /etc/amplify-agent/agent.conf 'mysql' 'user' 'root'
  crudini --set /etc/amplify-agent/agent.conf 'mysql' 'password' $DB_ROOT_PASS
  crudini --set /etc/amplify-agent/agent.conf 'credentials' 'hostname' `hostname -f`
  crudini --set /etc/amplify-agent/agent.conf 'extensions' 'phpfpm' 'True'
  crudini --set /etc/amplify-agent/agent.conf 'extensions' 'mysql' 'True'
  systemctl restart amplify-agent
fi

echo '- Installing phpMyAdmin'
#-----------------------------------------------------------------------------------------
# 08 - Installing phpMyAdmin
#-----------------------------------------------------------------------------------------
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

echo '- Configure PowerDNS'
#-----------------------------------------------------------------------------------------
# 09 - Configure PowerDNS Authorative
#-----------------------------------------------------------------------------------------
mysql -uroot -p"$DB_ROOT_PASS" -e "CREATE DATABASE IF NOT EXISTS $CP_DB_NAME"
mysql -uroot -p"$DB_ROOT_PASS" -e "CREATE USER IF NOT EXISTS '$CP_DB_NAME'@'$DB_BIND_ADDR' IDENTIFIED BY '$CP_DB_PASS'"
mysql -uroot -p"$DB_ROOT_PASS" -e "GRANT ALL PRIVILEGES ON $CP_DB_NAME.* TO '$CP_DB_NAME'@'$DB_BIND_ADDR'"
mysql -uroot -p"$DB_ROOT_PASS" -e "FLUSH PRIVILEGES"

mysql -uroot -p"$DB_ROOT_PASS" $CP_DB_NAME < $PWD/schema.sql

rm -fr /etc/powerdns ; cp -r $PWD/config/powerdns /etc ; chown -R root: /etc/powerdns
crudini --set /etc/powerdns/pdns.d/pdns.local.conf  '' 'gmysql-host'     $DB_BIND_ADDR
crudini --set /etc/powerdns/pdns.d/pdns.local.conf  '' 'gmysql-user'     $CP_DB_NAME
crudini --set /etc/powerdns/pdns.d/pdns.local.conf  '' 'gmysql-dbname'   $CP_DB_NAME
crudini --set /etc/powerdns/pdns.d/pdns.local.conf  '' 'gmysql-password' $CP_DB_PASS
crudini --set /etc/powerdns/pdns.conf '' 'webserver-password' 'secret'
crudini --set /etc/powerdns/pdns.conf '' 'api-key' $(pwgen -1 24)
crudini --set /etc/powerdns/pdns.conf '' 'launch' 'gmysql'
systemctl restart pdns


echo '- Configure ProFTPd'
#-----------------------------------------------------------------------------------------
# 10 - Configure ProFTPd
#-----------------------------------------------------------------------------------------
[[ $(cat /etc/group | grep -c ftpgroup) -eq 1 ]] || groupadd -g 2001 ftpgroup
[[ $(cat /etc/passwd | grep -c ftpuser) -eq 1 ]] || useradd -u 2001 -s /bin/false -d /bin/null -g ftpgroup ftpuser

iptables -A INPUT -p tcp -m tcp --dport 50000:50100 -j ACCEPT
netfilter-persistent save ; netfilter-persistent reload

curl -L# https://2ton.com.au/dhparam/2048 -o /etc/ssl/private/proftpd-dhparam.pem
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/proftpd.key -out /etc/ssl/certs/proftpd.crt -subj "/CN=$(hostname -f)"
chmod 0600 /etc/ssl/private/proftpd.key
chmod 0640 /etc/ssl/private/proftpd.key

rm -fr /etc/proftpd
cp -r $PWD/config/proftpd /etc
chown -R root: /etc/proftpd
sed -i "s/DB_NAME/$CP_DB_NAME/" /etc/proftpd/conf.d/sql.conf
sed -i "s/DB_PASS/$CP_DB_PASS/" /etc/proftpd/conf.d/sql.conf
sed -i "s/DB_HOST/$DB_BIND_ADDR/" /etc/proftpd/conf.d/sql.conf
systemctl restart proftpd


echo '- Installing Redis Cache'
#-----------------------------------------------------------------------------------------
# Redis Cache
#-----------------------------------------------------------------------------------------
if [ $SETUP_REDIS == "yes" ]; then
  apt install -y sysfsutils redis-{server,tools}
  echo 'kernel/mm/transparent_hugepage/enabled = never' > /etc/sysfs.conf
  echo 'kernel/mm/transparent_hugepage/defrag = never' >> /etc/sysfs.conf
  echo never > /sys/kernel/mm/transparent_hugepage/enabled
  echo never > /sys/kernel/mm/transparent_hugepage/defrag

  crudini --set /etc/sysctl.conf '' 'vm.overcommit_memory' '1'
  crudini --set /etc/sysctl.conf '' 'net.core.somaxconn' '512'
  echo 512 > /proc/sys/net/core/somaxconn
  mkdir -p /var/run/redis

  sed -i "s/supervised no/supervised systemd/" /etc/redis/redis.conf
  sed -i "s/# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/" /etc/redis/redis.conf
  sed -i "s/# maxmemory <bytes>/maxmemory 256mb/" /etc/redis/redis.conf
  sed -i "s|\("^bind" * *\).*|\1$DB_BIND_ADDR|" /etc/redis/redis.conf
  systemctl restart redis-server
fi

#-----------------------------------------------------------------------------------------
# 12 - Installing IMAPSync
#-----------------------------------------------------------------------------------------
if [ $SETUP_IMAPSYNC == "yes" ]; then
  echo '- Installing IMAPSync'
  apt install -y make cpanminus libauthen-ntlm-perl libclass-load-perl libcrypt-ssleay-perl \
  libdata-uniqid-perl libdigest-hmac-perl libdist-checkconflicts-perl libio-compress-perl \
  libfile-copy-recursive-perl libio-socket-inet6-perl libio-socket-ssl-perl libio-tee-perl \
  libmail-imapclient-perl libmodule-scandeps-perl libnet-ssleay-perl libpar-packer-perl \
  libreadonly-perl libregexp-common-perl libsys-meminfo-perl libterm-readkey-perl \
  libtest-fatal-perl libtest-mock-guard-perl libtest-pod-perl libtest-requires-perl \
  libtest-simple-perl libunicode-string-perl liburi-perl libtest-nowarnings-perl \
  libtest-deep-perl libtest-warn-perl

  cpanm Sys::MemInfo Data::Uniqid Mail::IMAPClient Email::Address JSON::WebToken
  git clone https://github.com/imapsync/imapsync.git /usr/src/imapsync
  cp /usr/src/imapsync/imapsync /usr/bin ; imapsync --testslive
fi

#-----------------------------------------------------------------------------------------
# 13 - Configure Telegram Notification
#-----------------------------------------------------------------------------------------
cp $PWD/sshnotify.sh /etc/profile.d/tg-alert.sh ; chmod a+x /etc/profile.d/tg-alert.sh
echo -e "USERID='$TELEGRAM_USERID'\nBOTKEY='$TELEGRAM_BOTKEY'" > /etc/sshnotify.conf

echo '- Installation finish, congratulation!'
