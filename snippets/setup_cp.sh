#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

PMA_DIR="/var/www/myadmin"
echo "ecp_`pwgen -1 -A 8`" > /tmp/ecp_dbname
echo `pwgen -1 12` > /tmp/ecp_dbpass

CP_DB_NAME=`cat /tmp/ecp_dbname`
CP_DB_PASS=`cat /tmp/ecp_dbpass`
DB_BINDADR=`cat /tmp/db_bindaddr`

mysql -uroot -p"`cat /tmp/ecp_dbpass`" -e "CREATE DATABASE IF NOT EXISTS `cat /tmp/ecp_dbname`"
mysql -uroot -p"`cat /tmp/ecp_dbpass`" -e "CREATE USER IF NOT EXISTS '$CP_DB_NAME'@'$DB_BINDADR' IDENTIFIED BY '$CP_DB_PASS'"
mysql -uroot -p"`cat /tmp/ecp_dbpass`" -e "GRANT ALL PRIVILEGES ON $CP_DB_NAME.* TO '$CP_DB_NAME'@'$DB_BINDADR'"
mysql -uroot -p"`cat /tmp/ecp_dbpass`" -e "FLUSH PRIVILEGES"
mysql -uroot -p"`cat /tmp/ecp_dbpass`" `cat /tmp/ecp_dbname` < $ROOT/dbschema.sql
perl -pi -e 's#(.*host.*= )(.*)#${1}"'`cat /tmp/db_bindaddr`'";#' $PMA_DIR/config.inc.php