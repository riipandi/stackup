#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PWD=$(dirname `dirname $(readlink -f $0)`) || PWD=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

# Get configuration parameter
#-----------------------------------------------------------------------------------------
touch "$PWD/stackup.ini"
[[ $(cat "$PWD/stackup.ini" | grep -c "mysql_version") -eq 1 ]] && mysql_version=$(crudini --get $PWD/stackup.ini '' 'mysql_version')
[[ -z "$mysql_version" ]] && read -ep "Select MariaDB version            (10.3 / 10.4) : " -i "10.3" mysql_version

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
echo -e "\n${OK}Installing MariaDB ${mysql_version}...${NC}"
COUNTRY=$(wget -qO- ipapi.co/json | grep '"country":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ $COUNTRY == "ID" ] ; then
    REPO="deb http://mariadb.biz.net.id/repo/$mysql_version/ubuntu `lsb_release -cs` main"
elif [ $COUNTRY == "SG" ] ; then
    REPO="deb http://download.nus.edu.sg/mirror/mariadb/repo/$mysql_version/ubuntu `lsb_release -cs` main"
else
    REPO="deb http://mirror.rackspace.com/mariadb/repo/$mysql_version/ubuntu `lsb_release -cs` main"
fi

echo $REPO > /etc/apt/sources.list.d/mariadb.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C74CD1D8 ; apt update -qq
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_ROOT_PASS"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_ROOT_PASS"
apt full-upgrade -y ; apt -y install mariadb-server mariadb-client

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

mysql -uroot -p$DB_ROOT_PASS -e "update mysql.user SET plugin='' where User='root';
drop database if exists test; flush privileges;"
