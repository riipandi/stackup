#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PWD=$(dirname `dirname $(readlink -f $0)`) || PWD=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

# Get configuration parameter
#-----------------------------------------------------------------------------------------
touch "$PWD/stackup.ini"
[[ $(cat "$PWD/stackup.ini" | grep -c "mysql_version") -eq 1 ]] && mysql_version=$(crudini --get $PWD/stackup.ini '' 'mysql_version')
[[ -z "$mysql_version" ]] && read -ep "Select MySQL version                (5.7 / 8.0) : " -i "8.0" mysql_version

[[ $(cat "$PWD/stackup.ini" | grep -c "mysql_bind_address") -eq 1 ]] && mysql_bind_address=$(crudini --get $PWD/stackup.ini '' 'mysql_bind_address')
[[ -z "$mysql_bind_address" ]] && read -ep "Database bind address                           : " -i "127.0.0.1" mysql_bind_address

[[ $(cat "$PWD/stackup.ini" | grep -c "mysql_listen_port") -eq 1 ]] && mysql_listen_port=$(crudini --get $PWD/stackup.ini '' 'mysql_listen_port')
[[ -z "$mysql_listen_port" ]] && read -ep "Database listen port                            : " -i "3306" mysql_listen_port

[[ $(cat "$PWD/stackup.ini" | grep -c "mysql_root_user") -eq 1 ]] && mysql_root_user=$(crudini --get $PWD/stackup.ini '' 'mysql_root_user')
[[ -z "$mysql_root_user" ]] && read -ep "Database root user                              : " -i "root" mysql_root_user

[[ $(cat "$PWD/stackup.ini" | grep -c "mysql_root_pass") -eq 1 ]] && mysql_root_pass=$(crudini --get $PWD/stackup.ini '' 'mysql_root_pass')
[[ -z "$mysql_root_pass" ]] && read -ep "Database root password                          : " -i "auto" mysql_root_pass

if [[ "$mysql_root_pass" == "auto" ]] ; then
    DB_ROOT_PASS=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-25)
    echo "MSQL_ROOT_PASS:$DB_ROOT_PASS" >> /usr/local/share/stackup.info
else
    DB_ROOT_PASS=$mysql_root_pass
fi

# Install packages
#-----------------------------------------------------------------------------------------
touch /etc/apt/sources.list.d/mysql.list
{
    echo "deb http://repo.mysql.com/apt/ubuntu/ `lsb_release -cs` mysql-$mysql_version"
    echo "deb http://repo.mysql.com/apt/ubuntu/ `lsb_release -cs` mysql-tools"
} > /etc/apt/sources.list.d/mysql.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 5072E1F5 && apt update

debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password $DB_ROOT_PASS"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password $DB_ROOT_PASS"
debconf-set-selections <<< "mysql-community-server mysql-community-server/remove-data-dir boolean false"
if [[ "$mysql_version" == "8.0" ]] ; then
    debconf-set-selections <<< "mysql-community-server mysql-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)"
fi
apt -y full-upgrade; apt -y install mysql-server mysql-client

# Configure packages
#-----------------------------------------------------------------------------------------
rm -f /etc/mysql/mysql.conf.d/default-auth-override.cnf

crudini --set /etc/mysql/conf.d/mysqld.cnf 'mysqld' 'default-authentication-plugin' 'mysql_native_password'
crudini --set /etc/mysql/conf.d/mysqld.cnf 'mysqld' 'bind-address' $mysql_bind_address
crudini --set /etc/mysql/conf.d/mysqld.cnf 'mysqld' 'port' $mysql_listen_port

crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'host'      $mysql_bind_address
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'port'      $mysql_listen_port
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'user'      $mysql_root_user
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql' 'password'  $DB_ROOT_PASS

crudini --set /etc/mysql/conf.d/mysqldump.cnf 'mysqldump' 'host'      $mysql_bind_address
crudini --set /etc/mysql/conf.d/mysqldump.cnf 'mysqldump' 'port'      $mysql_listen_port
crudini --set /etc/mysql/conf.d/mysqldump.cnf 'mysqldump' 'user'      $mysql_root_user
crudini --set /etc/mysql/conf.d/mysqldump.cnf 'mysqldump' 'password'  $DB_ROOT_PASS
systemctl restart mysql

# Change default mysql root user
mysql -uroot -p$DB_ROOT_PASS -e "drop database if exists test;
update mysql.user set User='$mysql_root_user' where User='root';
flush privileges;"
