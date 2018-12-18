#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

root_passwd=`crudini --get $ROOT/config.ini mysql root_pass`
bindaddress=`crudini --get $ROOT/config.ini mysql bind_address`

sed -i "s/skip-external-locking//" /etc/mysql/my.cnf
mysql -uroot -p$root_passwd -e "UPDATE mysql.user SET plugin='' WHERE User='root';"
crudini --set /etc/mysql/conf.d/mariadb.cnf 'mysqld' 'bind-address'  $bindaddress

crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'host'             $bindaddress
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'password'         $root_passwd
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'user'             'root'
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysqldump' 'user'         'root'
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysqldump' 'password'     $root_passwd
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysqldump' 'host'         $bindaddress
