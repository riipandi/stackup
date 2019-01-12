#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

[ -z $ROOT ] && PARENT=$(dirname "$(readlink -f "$0")") || PARENT=$ROOT

# Get parameter
#-----------------------------------------------------------------------------------------
ROOT_USER="root"
ROOT_PASS=`crudini --get $PARENT/config.ini mysql root_pass`
BIND_ADDR=`crudini --get $PARENT/config.ini mysql bind_address`

# Install packages
#-----------------------------------------------------------------------------------------
echo "deb http://sgp1.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/mariadb.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C74CD1D8 ; apt update -qq
debconf-set-selections <<< "mysql-server mysql-server/root_password password $ROOT_PASS"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $ROOT_PASS"
apt full-upgrade -y ; apt -y install mariadb-server mariadb-client

# Configure packages
#-----------------------------------------------------------------------------------------

sed -i "s/skip-external-locking//" /etc/mysql/my.cnf

mysql -uroot -p$ROOT_PASS -e "UPDATE mysql.user SET plugin='' WHERE User='root';"

crudini --set /etc/mysql/conf.d/mariadb.cnf 'mysqld' 'bind-address'  $BIND_ADDR

crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql'     'host'         $BIND_ADDR
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql'     'password'     $ROOT_PASS
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql'     'user'         $ROOT_USER

crudini --set /etc/mysql/conf.d/mysql.cnf 'mysqldump' 'user'         $ROOT_USER
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysqldump' 'password'     $ROOT_PASS
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysqldump' 'host'         $BIND_ADDR

systemctl restart mysql

mysql -uroot -p$ROOT_PASS -e "drop database if exists test;"
