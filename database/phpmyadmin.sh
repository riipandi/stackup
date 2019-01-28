#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

[ -z $ROOT ] && PARENT=$(dirname "$(readlink -f "$0")") || PARENT=$ROOT

# Install phpMyAdmin
#-----------------------------------------------------------------------------------------
echo "Installing phpMyAdmin ..."

[[ ! -d /var/www/myadmin ]] || rm -fr /var/www/myadmin

curl -fsSL https://phpmyadmin.net/downloads/phpMyAdmin-latest-english.zip | bsdtar -xvf- -C /tmp
mv /tmp/phpMyAdmin*english /var/www/myadmin

cat > /var/www/myadmin/config.inc.php <<EOF
<?php
\$cfg['blowfish_secret'] = '`openssl rand -hex 16`';
\$i = 0; \$i++;
\$cfg['Servers'][\$i]['auth_type']       = 'cookie';
\$cfg['Servers'][\$i]['host']            = '127.0.0.1';
\$cfg['Servers'][\$i]['connect_type']    = 'tcp';
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;
\$cfg['Servers'][\$i]['hide_db']         = '^(information_schema|performance_schema|mysql|phpmyadmin|sys)\$';
\$cfg['MaxRows']                         = 100;
\$cfg['SendErrorReports']                = 'never';
\$cfg['ShowDatabasesNavigationAsTree']   = false;
EOF

chmod 0755 /var/www/myadmin
find /var/www/myadmin/. -type d -exec chmod 0777 {} \;
find /var/www/myadmin/. -type f -exec chmod 0644 {} \;
chown -R www-data: /var/www/myadmin

# Install Adminer
#-----------------------------------------------------------------------------------------
echo "Installing Adminer ..."

[[ ! -d /var/www/adminer ]] && mkdir -p /var/www/adminer/plugins

cp $PARENT/nginx/adminer.php /var/www/adminer/index.php

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
