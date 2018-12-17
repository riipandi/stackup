#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

rootdbpass=`crudini --get $ROOT/install.ini mysql root_pass`
bind_address=`crudini --get $ROOT/install.ini mysql bind_address`

echo "deb http://mirror.jaleco.com/mariadb/repo/10.3/debian `lsb_release -cs` main" > /etc/apt/sources.list.d/mariadb.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C74CD1D8 #MariaDB

debconf-set-selections <<< "mysql-server mysql-server/root_password password $rootdbpass"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $rootdbpass"

apt update ; apt -y install mariadb-server mariadb-client

#-----------------------------------------------------------------------------------------
# 02 - Configuring MySQL
#-----------------------------------------------------------------------------------------
sed -i "s/skip-external-locking//" /etc/mysql/my.cnf
mysql -uroot -p$rootdbpass" -e "UPDATE mysql.user SET plugin='' WHERE User='root';"
crudini --set /etc/mysql/conf.d/mariadb.cnf 'mysqld' 'bind-address' $bind_address
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'host'     $bind_address
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'password' $rootdbpass
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'user'     'root'

crudini --set /etc/mysql/conf.d/mysql.cnf 'mysqldump' 'host'     $bind_address
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysqldump' 'password' $rootdbpass
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysqldump' 'user'     'root'
