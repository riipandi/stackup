#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

PWD=$(dirname "$(readlink -f "$0")")
PARENT=$(dirname "$PWD")


# Get parameter
#-----------------------------------------------------------------------------------------
ROOT_USER="root"
ROOT_PASS=`crudini --get $ROOT/config.ini mysql root_pass`
BIND_ADDR=`crudini --get $ROOT/config.ini mysql bind_address`

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
crudini --set /etc/mysql/mysql.conf.d/mysqld.cnf 'mysqld' 'port' '3306'

crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'host'  $BIND_ADDR
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'port'  '3306'

systemctl restart mysql

mysql -uroot -psecret -e "drop database if exists test;"
