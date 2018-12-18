#!/usr/bin/env bash

CURRENT=$(dirname "$(readlink -f "$0")")

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

password=`crudini --get $ROOT/config.ini mysql root_pass`

echo "deb http://mirror.jaleco.com/mariadb/repo/10.3/debian `lsb_release -cs` main" \
 > /etc/apt/sources.list.d/mariadb.list

apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C74CD1D8 #MariaDB

apt update -qq

debconf-set-selections <<< "mysql-server mysql-server/root_password password $password"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $password"

apt -yqq install mariadb-server mariadb-client

