#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

mkdir -p /var/www
PMA_DIR="/var/www/myadmin"

if [ ! -d $PMA_DIR ]; then
curl -fsSL https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-english.zip | bsdtar -xvf-
mv $PWD/phpMyAdmin*-english $PMA_DIR

chmod -R 0755 $PMA_DIR
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
