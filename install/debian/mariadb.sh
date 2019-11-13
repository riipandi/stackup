#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
NOCOLOR='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;33m'
BLUE='\033[0;34m'
CURRENT=$(dirname $(readlink -f $0))
[ -z $ROOTDIR ] && PWD=$(dirname `dirname $CURRENT`) || PWD=$ROOTDIR

# Parameter
#-----------------------------------------------------------------------------------------
mariadb_version="10.4"
mysql_bind_address="127.0.0.1"
mysql_listen_port="3306"
mysql_root_user="root"
mysql_root_pass="auto"

#-----------------------------------------------------------------------------------------
echo -e "\n${BLUE}Installing MariaDB ${mariadb_version}...${NOCOLOR}"
#-----------------------------------------------------------------------------------------
! [[ -z $(which mysql) ]] && echo -e "${BLUE}Already installed...${NOCOLOR}" && exit 1

# Install packages
#-----------------------------------------------------------------------------------------
COUNTRY=$(wget -qO- ipapi.co/json | grep '"country":' | sed -E 's/.*"([^"]+)".*/\1/')
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C74CD1D8 &>/dev/null

if [ $COUNTRY == "ID" ] ; then
    REPO="deb [arch=amd64] http://mirror.biznetgio.com/mariadb/repo/$mariadb_version/debian `lsb_release -cs` main"
elif [ $COUNTRY == "SG" ] ; then
    REPO="deb [arch=amd64] http://download.nus.edu.sg/mirror/mariadb/repo/$mariadb_version/debian `lsb_release -cs` main"
else
    REPO="deb [arch=amd64] http://mirror.rackspace.com/mariadb/repo/$mariadb_version/debian `lsb_release -cs` main"
fi
echo $REPO > /etc/apt/sources.list.d/mariadb.list

# Database root password
if [[ "$mysql_root_pass" == "auto" ]] ; then
    DB_ROOT_PASS=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-25)
    echo "MYSQL_ROOT_PASS = $DB_ROOT_PASS" >> /tmp/stackup-install.log
else
    DB_ROOT_PASS=$mysql_root_pass
fi

debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_ROOT_PASS"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_ROOT_PASS"
apt update -qq ; apt full-upgrade -yqq ; apt -yqq install mariadb-server mariadb-client

# Configure packages
#-----------------------------------------------------------------------------------------
sed -i "s/skip-external-locking//" /etc/mysql/my.cnf

crudini --set /etc/mysql/conf.d/mysqld.cnf 'mysqld' 'bind-address'  $mysql_bind_address
crudini --set /etc/mysql/conf.d/mysqld.cnf 'mysqld' 'port'          $mysql_listen_port

crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql'     'host'         $mysql_bind_address
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql'     'port'         $mysql_listen_port
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql'     'user'         $mysql_root_user
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql'     'password'     $DB_ROOT_PASS

crudini --set /etc/mysql/conf.d/mysql.cnf 'mysqldump' 'host'         $mysql_bind_address
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysqldump' 'port'         $mysql_listen_port
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysqldump' 'user'         $mysql_root_user
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysqldump' 'password'     $DB_ROOT_PASS

systemctl restart mysql

# Reset db root password
#-----------------------------------------------------------------------------------------
systemctl stop mysql
mysqld_safe --skip-grant-tables &
mysql -u root -e "FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASS';"
killall mysqld && systemctl restart mysql

# Disable plugin
#-----------------------------------------------------------------------------------------
mysql -uroot -p$DB_ROOT_PASS -e "update mysql.user SET plugin='' where User='root';
drop database if exists test; flush privileges;"
