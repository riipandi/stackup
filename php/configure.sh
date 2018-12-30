#!/usr/bin/env bash

default="7.2"

arr_ver=( '5.6' '7.2' '7.3' )

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

# Check default PHP version in installation config
if [[ ! -z $ROOT ]]; then
    default=`crudini --get $ROOT/config.ini php default`
elif [[ ! -z $1 ]]; then
    default=$1
fi

if [[ "${arr_ver[*]}" != *"$default"* ]]; then
    echo -e "\nThat PHP version doesnt' exist...\n"
    exit 1
fi

echo -e "\nConfiguring php-fpm, set default to v$default"

find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "upload_max_filesize" "32M"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "max_execution_time"  "300"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "max_input_time"      "300"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "post_max_size"       "16M"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "display_errors"      "Off"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "cgi.fix_pathinfo"    "0"'  {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "memory_limit"        "768M"' {} \;
find /etc/php/. -name 'php.ini'  -exec bash -c 'crudini --set "$0" "PHP" "expose_php"          "Off"' {} \;

find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm"                      "ondemand"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.max_children"         "32"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.start_servers"        "2"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.min_spare_servers"    "4"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.max_spare_servers"    "8"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.max_requests"         "256"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.process_idle_timeout" "10s"' {} \;
find /etc/php/. -name 'www.conf' -exec bash -c 'crudini --set "$0" "www" "pm.status_path" "/status"' {} \;

# Set default PHP version
echo
update-alternatives --set php /usr/bin/php$default >/dev/null 2>&1
update-alternatives --set phar /usr/bin/phar$default >/dev/null 2>&1
update-alternatives --set phar.phar /usr/bin/phar.phar$default >/dev/null 2>&1

phpenmod curl opcache imagick fileinfo

# Default PHP-FPM on Nginx configuration
find /etc/nginx/manifest/ -type f -exec sed -i "s/php.*.-fpm/php\/php${default}-fpm/g" {} +
find /etc/nginx/server.d/ -type f -exec sed -i "s/php.*.-fpm/php\/php${default}-fpm/g" {} +
sed -i "s/php.*.-fpm/php\/php${default}-fpm/g" /etc/nginx/conf.d/default.conf

echo -e "PHP-FPM has been configured...\n"
