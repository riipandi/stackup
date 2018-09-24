#!/bin/bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

country=`curl -s ipinfo.io | grep country | awk -F":" '{print $2}' | cut -d '"' -f2`

srcfile="/etc/apt/sources.list"
if [ "$country" == "ID" ] ; then
  echo "deb http://kebo.pens.ac.id/debian `lsb_release -cs` main contrib non-free" > /etc/apt/sources.list
  echo "deb http://kebo.pens.ac.id/debian `lsb_release -cs`-updates main contrib non-free" >> /etc/apt/sources.list
  echo "deb http://kebo.pens.ac.id/debian-security `lsb_release -cs`/updates main contrib non-free" >> /etc/apt/sources.list
  echo "deb http://mariadb.biz.net.id/repo/10.3/debian `lsb_release -cs` main" > /etc/apt/sources.list.d/lemp.list
elif [ "$country" == "SG" ] ; then
  echo "deb http://sgp1.mirrors.digitalocean.com/debian `lsb_release -cs` main contrib non-free" > /etc/apt/sources.list
  echo "deb http://sgp1.mirrors.digitalocean.com/debian `lsb_release -cs`-updates main contrib non-free" >> /etc/apt/sources.list
  echo "deb http://security.debian.org/debian-security `lsb_release -cs`/updates main contrib non-free" >> /etc/apt/sources.list
  echo "deb http://download.nus.edu.sg/mirror/mariadb/repo/10.3/debian `lsb_release -cs` main" > /etc/apt/sources.list.d/lemp.list
else
  echo "deb http://debian-archive.trafficmanager.net/debian `lsb_release -cs` main contrib non-free" > /etc/apt/sources.list
  echo "deb http://debian-archive.trafficmanager.net/debian `lsb_release -cs`-updates main contrib non-free" >> /etc/apt/sources.list
  echo "deb http://debian-archive.trafficmanager.net/debian-security `lsb_release -cs`/updates main contrib non-free" >> /etc/apt/sources.list
  echo "deb http://mirror.jaleco.com/mariadb/repo/10.3/debian `lsb_release -cs` main" > /etc/apt/sources.list.d/lemp.list
fi

cat >> /etc/apt/sources.list.d/lemp.list <<EOF
deb [arch=amd64] https://repo.powerdns.com/debian `lsb_release -cs`-auth-41 main
deb https://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main
deb https://nginx.org/packages/debian/ `lsb_release -cs` nginx
deb https://deb.nodesource.com/node_8.x `lsb_release -cs` main
deb https://packages.sury.org/php/ `lsb_release -cs` main
EOF

apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C74CD1D8 #MariaDB
curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc   | apt-key add -
curl -sS https://nginx.org/keys/nginx_signing.key             | apt-key add -
curl -sS https://packages.sury.org/php/apt.gpg                | apt-key add -
curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
curl -sS https://repo.powerdns.com/FD380FBB-pub.asc           | apt-key add -

echo -e "Package: pdns-*\nPin: origin repo.powerdns.com\nPin-Priority: 600" > /etc/apt/preferences.d/pdns

echo 'Repository has been configured'
