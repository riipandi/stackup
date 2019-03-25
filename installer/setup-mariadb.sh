#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PARENT=$(dirname `dirname $(readlink -f $0)`) || PARENT=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

read -ep "Select MariaDB version            (10.3 / 10.4) : " -i "10.3" mariadb_version
read -ep "Database bind address                           : " -i "127.0.0.1" mariadb_bind_address
read -ep "Database listen port                            : " -i "3306" mariadb_listen_port
read -ep "Database root user                              : " -i "root" mariadb_root_user
read -ep "Database root password                          : " -i "auto" mariadb_root_pass

if [[ "$mariadb_root_pass" == "auto" ]] ; then
    DB_ROOT_PASS=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-25)
    echo "MSQL_ROOT_PASS:$DB_ROOT_PASS" >> /usr/local/share/stackup.info
else
    DB_ROOT_PASS=$mariadb_root_pass
fi

# Install packages
#-----------------------------------------------------------------------------------------
echo "deb http://sgp1.mirrors.digitalocean.com/mariadb/repo/$mariadb_version/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/mariadb.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C74CD1D8 ; apt update -qq
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_ROOT_PASS"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_ROOT_PASS"
apt full-upgrade -y ; apt -y install mariadb-server mariadb-client

# Configure packages
#-----------------------------------------------------------------------------------------
sed -i "s/skip-external-locking//" /etc/mysql/my.cnf

crudini --set /etc/mysql/conf.d/mariadb.cnf 'mysqld' 'bind-address'  $mariadb_bind_address
crudini --set /etc/mysql/conf.d/mariadb.cnf 'mysqld' 'pot'           $mariadb_listen_port

crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql'     'host'         $mariadb_bind_address
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql'     'port'         $mariadb_listen_port
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql'     'user'         $mariadb_root_user
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysql'     'password'     $DB_ROOT_PASS

crudini --set /etc/mysql/conf.d/mysql.cnf 'mysqldump' 'host'         $mariadb_bind_address
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysqldump' 'port'         $mariadb_listen_port
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysqldump' 'user'         $mariadb_root_user
crudini --set /etc/mysql/conf.d/mysql.cnf 'mysqldump' 'password'     $DB_ROOT_PASS

systemctl restart mysql

mysql -uroot -p$DB_ROOT_PASS -e "update mysql.user SET plugin='' where User='root';
drop database if exists test; flush privileges;"
