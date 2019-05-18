#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PARENT=$(dirname `dirname $(readlink -f $0)`) || PARENT=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

echo -e "\n${OK}Installing Adminer...${NC}"

[[ ! -d /var/www ]] && mkdir -p /var/www
[[ ! -d /var/www/adminer ]] && mkdir -p /var/www/adminer/plugins

cp $PARENT/stubs/adminer.php /var/www/adminer/index.php

curl -fsSL https://github.com/vrana/adminer/releases/download/v4.7.1/adminer-4.7.1-en.php -o /var/www/adminer/adminer.php
curl -fsSL https://raw.githubusercontent.com/vrana/adminer/master/designs/rmsoft/adminer.css -o /var/www/adminer/adminer.css
curl -fsSL https://raw.github.com/vrana/adminer/master/plugins/plugin.php -o /var/www/adminer/plugin.php
curl -fsSL https://raw.github.com/vrana/adminer/master/plugins/foreign-system.php -o /var/www/adminer/plugins/foreign-system.php
curl -fsSL https://raw.github.com/vrana/adminer/master/plugins/login-servers.php -o /var/www/adminer/plugins/login-servers.php
curl -fsSL https://raw.github.com/vrana/adminer/master/plugins/database-hide.php -o /var/www/adminer/plugins/database-hide.php
curl -fsSL https://raw.github.com/vrana/adminer/master/plugins/edit-foreign.php -o /var/www/adminer/plugins/edit-foreign.php
curl -fsSL https://raw.github.com/vrana/adminer/master/plugins/dump-zip.php -o /var/www/adminer/plugins/dump-zip.php

chmod 0755 /var/www/adminer
find /var/www/adminer/. -type d -exec chmod 0777 {} \;
find /var/www/adminer/. -type f -exec chmod 0644 {} \;
chown -R www-data: /var/www/adminer
