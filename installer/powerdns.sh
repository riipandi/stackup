#!/bin/bash

PWD=$(dirname "$(readlink -f "$0")")
PARENT=$(dirname $PWD)

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

debconf-set-selections <<< "pdns-backend-mysql pdns-backend-mysql/dbconfig-install boolean false"

apt -y install pdns-{server,backend-mysql}

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

