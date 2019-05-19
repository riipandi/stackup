#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PWD=$(dirname `dirname $(readlink -f $0)`) || PWD=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

echo -e "\n${OK}Installing phpMyAdmin...${NC}"

[[ ! -d /var/www ]] && mkdir -p /var/www
[[ ! -d /var/www/myadmin ]] || rm -fr /var/www/myadmin

[[ $(cat /etc/group | grep -c webmaster) -eq 1 ]] || groupadd -g 2001 webmaster
[[ $(cat /etc/passwd | grep -c webmaster) -eq 1 ]] || useradd -u 2001 -s /usr/sbin/nologin -d /bin/null -g webmaster webmaster

curl -fsSL https://phpmyadmin.net/downloads/phpMyAdmin-latest-english.zip | bsdtar -xvf- -C /tmp
mv /tmp/phpMyAdmin*english /var/www/myadmin ; cat > /var/www/myadmin/config.inc.php <<EOF
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
chown -R webmaster:webmaster /var/www/myadmin
