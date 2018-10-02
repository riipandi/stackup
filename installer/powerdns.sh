#!/bin/bash

PWD=$(dirname "$(readlink -f "$0")")
PARENT=$(dirname $PWD)

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

#-----------------------------------------------------------------------------------------
# Install PowerDNS Authorative
#-----------------------------------------------------------------------------------------

echo -e "Package: pdns-*\nPin: origin repo.powerdns.com\nPin-Priority: 600" > /etc/apt/preferences.d/pdns
echo "deb [arch=amd64] https://repo.powerdns.com/debian `lsb_release -cs`-auth-41 main" > /etc/apt/sources.list.d/pdns.list
curl -sS https://repo.powerdns.com/FD380FBB-pub.asc | apt-key add -

debconf-set-selections <<< "pdns-backend-mysql pdns-backend-mysql/dbconfig-install boolean false"

apt update ; apt -y install pdns-{server,backend-mysql}


#-----------------------------------------------------------------------------------------
# Configure PowerDNS Authorative
#-----------------------------------------------------------------------------------------

CP_DB_NAME=`cat /tmp/ecp_dbname`
CP_DB_PASS=`cat /tmp/ecp_dbpass`
DB_BINDADR=`cat /tmp/db_bindaddr`

mysql -uroot -p"`cat /tmp/ecp_dbpass`" -e "CREATE USER IF NOT EXISTS '$CP_DB_NAME'@'$DB_BINDADR' IDENTIFIED BY '$CP_DB_PASS'"
mysql -uroot -p"`cat /tmp/ecp_dbpass`" -e "GRANT ALL PRIVILEGES ON $CP_DB_NAME.* TO '$CP_DB_NAME'@'$DB_BINDADR'"
mysql -uroot -p"`cat /tmp/ecp_dbpass`" -e "FLUSH PRIVILEGES"

rm -fr /etc/powerdns ; cp -r $PARENT/config/powerdns /etc ; chown -R root: /etc/powerdns
crudini --set /etc/powerdns/pdns.d/pdns.local.conf  '' 'gmysql-host'     $DB_BINDADR
crudini --set /etc/powerdns/pdns.d/pdns.local.conf  '' 'gmysql-user'     $CP_DB_NAME
crudini --set /etc/powerdns/pdns.d/pdns.local.conf  '' 'gmysql-dbname'   $CP_DB_NAME
crudini --set /etc/powerdns/pdns.d/pdns.local.conf  '' 'gmysql-password' $CP_DB_PASS
crudini --set /etc/powerdns/pdns.conf '' 'webserver-password' $(pwgen -1 12)
crudini --set /etc/powerdns/pdns.conf '' 'api-key' $(pwgen -1 24)
crudini --set /etc/powerdns/pdns.conf '' 'launch' 'gmysql'
systemctl restart pdns
