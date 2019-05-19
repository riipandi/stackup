#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PWD=$(dirname `dirname $(readlink -f $0)`) || PWD=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

# Get configuration parameter
#-----------------------------------------------------------------------------------------
touch "$PWD/stackup.ini"
if [ -f "$PWD/stackup.ini" ]; then
    [[ $(cat "$PWD/stackup.ini" | grep -c "install_php_73") -eq 1 ]] && install_php_73=$(crudini --get $PWD/stackup.ini '' 'install_php_73')
    [[ -z "$install_php_73" ]] && read -ep "Install PHP 7.3 ?                           y/n : " -i "y" install_php_73

    [[ $(cat "$PWD/stackup.ini" | grep -c "install_php_72") -eq 1 ]] && install_php_72=$(crudini --get $PWD/stackup.ini '' 'install_php_72')
    [[ -z "$install_php_72" ]] && read -ep "Install PHP 7.2 ?                           y/n : " -i "y" install_php_72

    [[ $(cat "$PWD/stackup.ini" | grep -c "install_php_56") -eq 1 ]] && install_php_56=$(crudini --get $PWD/stackup.ini '' 'install_php_56')
    [[ -z "$install_php_56" ]] && read -ep "Install PHP 5.6 ?                           y/n : " -i "y" install_php_56

    [[ $(cat "$PWD/stackup.ini" | grep -c "default_php") -eq 1 ]] && default_php=$(crudini --get $PWD/stackup.ini '' 'default_php')
    [[ -z "$default_php" ]] && read -ep "Default PHP version ?                           : " -i "7.3" default_php
fi

# Change PHP repository
#-----------------------------------------------------------------------------------------
echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/sury-php.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com E5267A6C && apt update

# ionCube loader
curl -fsSL https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz | bsdtar -xvf- -C /usr/share

# Install packages
#-----------------------------------------------------------------------------------------
[[ -d /run/php ]] || mkdir -p /run/php ; [[ -d /var/run/php ]] || mkdir -p /var/run/php

if [[ "${install_php_73,,}" =~ ^(yes|y)$ ]] ; then
    echo -e "\n${OK}Installing PHP v7.3...${NC}"
    apt -y install php7.3-{bcmath,cgi,cli,common,curl,fpm,gd,gmp,imap,intl,json,ldap,mbstring,mysql,opcache,pgsql,readline,soap,sqlite3,xml,xmlrpc,zip,zip} php7.3 php7.3-imagick php-pear
    find /etc/php/7.3/. -name 'php.ini' -exec bash -c 'crudini --set "$0" "PHP" "zend_extension" "/usr/share/ioncube/ioncube_loader_lin_7.3.so"' {} \;
    crudini --set /etc/php/7.3/fpm/pool.d/www.conf 'www' 'listen' '/var/run/php/php7.3-fpm.sock'
    phpenmod curl opcache imagick fileinfo
    systemctl restart php7.3-fpm
fi

if [[ "${install_php_72,,}" =~ ^(yes|y)$ ]] ; then
    echo -e "\n${OK}Installing PHP v7.2...${NC}"
    apt -y install php7.2-{bcmath,cgi,cli,common,curl,fpm,gd,gmp,imap,intl,json,ldap,mbstring,mysql,opcache,pgsql,readline,soap,sqlite3,xml,xmlrpc,zip,zip} php7.2
    find /etc/php/7.2/. -name 'php.ini' -exec bash -c 'crudini --set "$0" "PHP" "zend_extension" "/usr/share/ioncube/ioncube_loader_lin_7.2.so"' {} \;
    crudini --set /etc/php/7.2/fpm/pool.d/www.conf 'www' 'listen' '/var/run/php/php7.2-fpm.sock'
    phpenmod curl opcache imagick fileinfo
    systemctl restart php7.2-fpm
fi

if [[ "${install_php_56,,}" =~ ^(yes|y)$ ]] ; then
    echo -e "\n${OK}Installing PHP v5.6...${NC}"
    apt -y install php5.6-{bcmath,cgi,cli,common,curl,fpm,gd,gmp,imap,intl,json,ldap,mbstring,mysql,opcache,pgsql,readline,soap,sqlite3,xml,xmlrpc,zip,zip} php5.6 php-apcu
    find /etc/php/5.6/. -name 'php.ini' -exec bash -c 'crudini --set "$0" "PHP" "zend_extension" "/usr/share/ioncube/ioncube_loader_lin_5.6.so"' {} \;
    crudini --set /etc/php/5.6/fpm/pool.d/www.conf 'www' 'listen' '/var/run/php/php5.6-fpm.sock'
    phpenmod curl opcache imagick fileinfo
    systemctl restart php5.6-fpm
fi

# Required package for all php version
apt -y install composer gettext gamin mcrypt imagemagick aspell graphviz

# PHP development packages
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Downloading PHP development packages...${NC}"
curl -L# "https://git.io/vN3Ff" -o /usr/local/bin/wp
curl -L# "https://git.io/fAFyN" -o /usr/local/bin/phpcs
curl -L# "https://git.io/fAFyb" -o /usr/local/bin/phpcbf
curl -L# "https://cs.sensiolabs.org/download/php-cs-fixer-v2.phar" -o /usr/local/bin/php-cs-fixer
chmod +x /usr/local/bin/* ; chown root: /usr/local/bin/*

# Configure packages
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Configuring PHP-FPM...${NC}"
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

[[ "${install_php_73,,}" =~ ^(yes|y)$ ]] && systemctl restart php7.3-fpm
[[ "${install_php_72,,}" =~ ^(yes|y)$ ]] && systemctl restart php7.2-fpm
[[ "${install_php_56,,}" =~ ^(yes|y)$ ]] && systemctl restart php5.6-fpm

# Set default PHP version
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Set default PHP to v$default_php${NC}\n"
update-alternatives --set php /usr/bin/php$default_php >/dev/null 2>&1
update-alternatives --set phar /usr/bin/phar$default_php >/dev/null 2>&1
update-alternatives --set phar.phar /usr/bin/phar.phar$default_php >/dev/null 2>&1
