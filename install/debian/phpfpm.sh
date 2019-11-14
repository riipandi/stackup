#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

# Determine root directory
[ -z $ROOTDIR ] && PWD=$(dirname `dirname $(dirname $(readlink -f $0))`) || PWD=$ROOTDIR

# Common global variables
source "$PWD/common.sh"

# Parameter
#-----------------------------------------------------------------------------------------
default_php="7.3"

#-----------------------------------------------------------------------------------------
msgSuccess "\n--- Installing PHP v${default_php}"
#-----------------------------------------------------------------------------------------
! [[ -z $(which php) ]] && msgError "Already installed..." && exit 1

# Create runtime directory
[[ -d /var/run/php ]] || mkdir -p /var/run/php
[[ -d /run/php ]] || mkdir -p /run/php

# Install packages
#-----------------------------------------------------------------------------------------
curl -sS https://packages.sury.org/php/apt.gpg | apt-key add - &>${logInstall}
cat > /etc/apt/sources.list.d/php.list <<EOF
deb https://packages.sury.org/php/ $(lsb_release -sc) main
EOF
pkgUpgrade

# ionCube loader extension
curl -fsSL https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz | bsdtar -xvf- -C /usr/share

# PHP v7.3
apt -y install php7.3-{bcmath,cgi,cli,common,curl,fpm,gd,gmp,imap,intl,json,ldap,mbstring,mysql} \
php7.3-{opcache,pgsql,readline,soap,sqlite3,xml,xmlrpc,zip,zip} php7.3 php7.3-imagick php-pear &>${logInstall}
find /etc/php/7.3/. -name 'php.ini' -exec bash -c 'crudini --set "$0" "PHP" "zend_extension" "/usr/share/ioncube/ioncube_loader_lin_7.3.so"' {} \;
crudini --set /etc/php/7.3/fpm/pool.d/www.conf 'www' 'listen' '/var/run/php/php7.3-fpm.sock'
phpenmod curl opcache imagick fileinfo && systemctl restart php7.3-fpm

# Required package for all php version
apt -yqq install composer gettext gamin mcrypt imagemagick aspell graphviz php-mailparse &>${logInstall}

# PHP development packages
#-----------------------------------------------------------------------------------------
msgInfo "Downloading PHP development packages..."
curl -L# "https://git.io/vN3Ff" -o /usr/local/bin/wp
curl -L# "https://git.io/fAFyN" -o /usr/local/bin/phpcs
curl -L# "https://git.io/fAFyb" -o /usr/local/bin/phpcbf
curl -L# "https://cs.sensiolabs.org/download/php-cs-fixer-v2.phar" -o /usr/local/bin/php-cs-fixer
chmod +x /usr/local/bin/* && chown root:root /usr/local/bin/*

# Configure packages
#-----------------------------------------------------------------------------------------
msgSuccess "\n--- Configuring PHP v${default_php}"
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "date.timezone"  "Asia/Jakarta"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "upload_max_filesize"     "32M"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "max_execution_time"      "300"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "max_input_time"          "300"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "post_max_size"           "16M"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "display_errors"          "Off"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "cgi.fix_pathinfo"         "0"'  {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "memory_limit"           "256M"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "expose_php"              "Off"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm"                 "ondemand"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.max_children"          "32"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.start_servers"          "2"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.min_spare_servers"      "4"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.max_spare_servers"      "8"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.max_requests"         "256"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.process_idle_timeout"  "5s"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.status_path"      "/status"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "listen.owner"      "webmaster"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "listen.group"      "webmaster"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "user"   "webmaster"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "group"  "webmaster"' {} \;
systemctl restart php7.3-fpm

# [[ "${install_php_73,,}" =~ ^(yes|y)$ ]] && systemctl restart php7.3-fpm
# [[ "${install_php_72,,}" =~ ^(yes|y)$ ]] && systemctl restart php7.2-fpm
# [[ "${install_php_56,,}" =~ ^(yes|y)$ ]] && systemctl restart php5.6-fpm

# Set default PHP version
#-----------------------------------------------------------------------------------------
msgInfo "Set default PHP to v${default_php}"
update-alternatives --set php /usr/bin/php$default_php >/dev/null 2>&1
update-alternatives --set phar /usr/bin/phar$default_php >/dev/null 2>&1
update-alternatives --set phar.phar /usr/bin/phar.phar$default_php >/dev/null 2>&1

# Default PHP-FPM on Nginx configuration
#-----------------------------------------------------------------------------------------
cat /etc/nginx/stubs/default.php > /usr/share/nginx/html/index.php
cat /etc/nginx/vhost.tpl/default-php.conf > /etc/nginx/conf.d/default.conf
sed -i "s/HOSTNAME/$(hostname -f)/"          /etc/nginx/conf.d/default.conf
sed -i "s/IPADDRESS/$(curl -s ifconfig.me)/" /etc/nginx/conf.d/default.conf

if [ -d "/etc/letsencrypt/live/$(hostname -f)" ]; then
    sed -i "s/# listen/listen/" /etc/nginx/conf.d/default.conf
    sed -i "s/# ssl_certificate/ssl_certificate/" /etc/nginx/conf.d/default.conf
    sed -i "s/# ssl_certificate_key/ssl_certificate_key/" /etc/nginx/conf.d/default.conf
fi

find /etc/nginx/vhost.tpl/ -type f -exec sed -i "s/php.*.-fpm/php\/php${default_php}-fpm/g" {} +
sed -i "s/php.*.-fpm/php\/php${default_php}-fpm/g" /etc/nginx/conf.d/default.conf
systemctl restart nginx
