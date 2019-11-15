#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOTDIR ] && PWD=$(dirname `dirname $(dirname $(readlink -f $0))`) || PWD=$ROOTDIR
source "$PWD/common.sh"

# Parameter
#-----------------------------------------------------------------------------------------
mariadb_version="10.4"
mysql_bind_address="127.0.0.1"
mysql_listen_port="3306"
mysql_root_user="root"
mysql_root_pass="auto"

#-----------------------------------------------------------------------------------------
msgSuccess "\n--- Installing MariaDB ${mariadb_version}"
#-----------------------------------------------------------------------------------------
! [[ -z $(which mysql) ]] && msgError "Already installed..." && exit 1

# Install packages
#-----------------------------------------------------------------------------------------
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C74CD1D8 &>${logInstall}

if [ $checkCountry == "ID" ] ; then
    REPO="deb [arch=amd64] http://mirror.biznetgio.com/mariadb/repo/$mariadb_version/debian `lsb_release -cs` main"
elif [ $checkCountry == "SG" ] ; then
    REPO="deb [arch=amd64] http://download.nus.edu.sg/mirror/mariadb/repo/$mariadb_version/debian `lsb_release -cs` main"
else
    REPO="deb [arch=amd64] http://mirror.rackspace.com/mariadb/repo/$mariadb_version/debian `lsb_release -cs` main"
fi
echo $REPO > /etc/apt/sources.list.d/mariadb.list

# Database root password
if [[ "$mysql_root_pass" == "auto" ]] ; then
    DB_ROOT_PASS=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-25)
else
    DB_ROOT_PASS=$mysql_root_pass
fi

pkgUpgrade
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_ROOT_PASS"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_ROOT_PASS"
apt -yq install mariadb-server mariadb-client &>${logInstall}

# Configure packages
#-----------------------------------------------------------------------------------------
msgSuccess "\n--- Configuring MariaDB ${mariadb_version}"
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
systemctl stop mysql && killall mysqld
mysqld_safe --skip-grant-tables >res 2>&1 &
mysql -u root -e "FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';"
killall mysqld && systemctl restart mysql

# Write log information
writeLogInfo 'mysql_password' $DB_ROOT_PASS

# Disable plugin
#-----------------------------------------------------------------------------------------
mysql -uroot -p${DB_ROOT_PASS} -e "update mysql.user SET plugin='' where User='root';"
mysql -uroot -p${DB_ROOT_PASS} -e "drop database if exists test; flush privileges;"
