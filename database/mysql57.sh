#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

[ -z $ROOT ] && PARENT=$(dirname "$(readlink -f "$0")") || PARENT=$ROOT

# Get parameter
#-----------------------------------------------------------------------------------------
ROOT_USER=`crudini --get $PARENT/config.ini mysql root_user`
ROOT_PASS=`crudini --get $PARENT/config.ini mysql root_pass`
BIND_ADDR=`crudini --get $PARENT/config.ini mysql bind_address`
BIND_PORT=`crudini --get $PARENT/config.ini mysql bind_port`

# Install packages
#-----------------------------------------------------------------------------------------
touch /etc/apt/sources.list.d/mysql.list
{
    echo "deb http://repo.mysql.com/apt/ubuntu/ `lsb_release -cs` mysql-5.7"
    echo "deb http://repo.mysql.com/apt/ubuntu/ `lsb_release -cs` mysql-tools"
} > /etc/apt/sources.list.d/mysql.list

apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 5072E1F5 && apt update

debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password $ROOT_PASS"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password $ROOT_PASS"
debconf-set-selections <<< "mysql-community-server mysql-community-server/remove-data-dir boolean false"
apt full-upgrade -y ; apt install -y mysql-server mysql-client

# Configure packages
#-----------------------------------------------------------------------------------------
rm -f /etc/mysql/mysql.conf.d/default-auth-override.cnf

crudini --set /etc/mysql/mysql.conf.d/mysqld.cnf 'mysqld' 'default-authentication-plugin' 'mysql_native_password'
crudini --set /etc/mysql/mysql.conf.d/mysqld.cnf 'mysqld' 'bind-address' $BIND_ADDR
crudini --set /etc/mysql/mysql.conf.d/mysqld.cnf 'mysqld' 'port' $BIND_PORT

crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'host'      $BIND_ADDR
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'port'      $BIND_PORT
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'user'      $ROOT_USER
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'password'  $ROOT_PASS

crudini --set /etc/mysql/conf.d/mysqldump.cnf 'mysqldump' 'host'      $BIND_ADDR
crudini --set /etc/mysql/conf.d/mysqldump.cnf 'mysqldump' 'port'      $BIND_PORT
crudini --set /etc/mysql/conf.d/mysqldump.cnf 'mysqldump' 'user'      $ROOT_USER
crudini --set /etc/mysql/conf.d/mysqldump.cnf 'mysqldump' 'password'  $ROOT_PASS
systemctl restart mysql

# Change default mysql root user
mysql -uroot -p$ROOT_PASS -e "drop database if exists test;"
mysql -uroot -p$ROOT_PASS mysql -e "update user set User='$ROOT_USER' where User='root'; flush privileges;"
