#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

PWD=$(dirname "$(readlink -f "$0")")

#-----------------------------------------------------------------------------------------
# Setup wizard
#-----------------------------------------------------------------------------------------

read -e -p "Install PHP v5.6     y/n : " -i "y" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then echo Yes > /tmp/install_php56 ;fi

read -e -p "Install PHP v7.2     y/n : " -i "y" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then echo No > /tmp/install_php72 ;fi

read -e -p "Install Python Stack y/n : " -i "y" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then echo Yes > /tmp/install_python ;fi

read -e -p "Install PostgreSQL   y/n : " -i "n" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then echo Yes > /tmp/install_pgsql ;fi

read -e -p "Install Redis Server y/n : " -i "n" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then echo Yes > /tmp/install_redis ;fi

read -e -p "Install FTP Server   y/n : " -i "n" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then echo Yes > /tmp/install_ftpd ;fi

read -e -p "Install DNS Server   y/n : " -i "n" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then echo Yes > /tmp/install_pdns ;fi

read -e -p "Install IMAP Sync    y/n : " -i "n" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then echo Yes > /tmp/install_imaps ;fi

read -e -p "Database Bind Address    : " -i "127.0.0.1" db_bindaddr
if [ "$db_bindaddr" != "" ] ;then
  echo "$db_bindaddr" > /tmp/db_bindaddr
else
  echo "127.0.0.1" > /tmp/db_bindaddr
fi


#-----------------------------------------------------------------------------------------
# Install the choosen packages
#-----------------------------------------------------------------------------------------
[[ "`cat /tmp/install_python`" != "Yes" ]] || source $PWD/installer/python.sh
[[ "`cat /tmp/install_pgsql`" != "Yes" ]] || source $PWD/installer/postgresql.sh
[[ "`cat /tmp/install_redis`" != "Yes" ]] || source $PWD/installer/rediscache.sh
[[ "`cat /tmp/install_ftpd`" != "Yes" ]] || source $PWD/installer/ftpserver.sh
[[ "`cat /tmp/install_pdns`" != "Yes" ]] || source $PWD/installer/powerdns.sh
[[ "`cat /tmp/install_imaps`" != "Yes" ]] || source $PWD/installer/imapsync.sh
