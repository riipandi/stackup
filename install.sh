#!/usr/bin/env bash

ROOT=$(dirname "$(readlink -f "$0")")

# Check if this script running as root
if [[ $EUID -ne 0 ]]; then
    echo -e 'This script must be run as root' ; exit 1
else
    read -p "Press enter to continue ..."
fi

SetConfigSetup() {
    crudini --set $ROOT/config.ini $1 $2 $3
}

GetConfigSetup() {
    crudini --get $ROOT/config.ini $1 $2
}

InstallPackage() {
    if [ `crudini --get $ROOT/config.ini $1 $2` == "yes" ]; then
        source $3
    fi
}

#-----------------------------------------------------------------------------------------
# Initial Setup
#-----------------------------------------------------------------------------------------
rm -f /etc/resolv.conf
echo 'nameserver 209.244.0.3' >  /etc/resolv.conf
echo 'nameserver 209.244.0.4' >> /etc/resolv.conf

# Upgrade basic system packages
source $ROOT/installer/00-repo.sh
source $ROOT/installer/01-basepkg.sh

#-----------------------------------------------------------------------------------------
# System setup
#-----------------------------------------------------------------------------------------
SetConfigSetup system country `curl -s ipinfo.io | grep country | awk -F":" '{print $2}' | cut -d '"' -f2`

read -sp "Enter new root password          : " rootpass
usermod root --password `openssl passwd -1 "$rootpass"`

echo -e ""
read -ep "Enter new user fullname          : " -i "Admin Sistem" fullname
read -ep "Enter new user username          : " -i "admin" username
read -sp "Enter new user password          : " userpass
useradd -mg sudo -s `which bash` $username -c "$fullname" -p `openssl passwd -1 "$userpass"`

echo -e ""
read -ep "Please specify SSH port          : " -i "22" ssh_port
SetConfigSetup system ssh_port $ssh_port

read -ep "Please specify time zone         : " -i "Asia/Jakarta" timezone
SetConfigSetup system timezone $timezone

read -ep "Disable IPv6            (yes/no) : " -i "no" disable_ipv6
SetConfigSetup system disable_ipv6 $disable_ipv6

#-----------------------------------------------------------------------------------------
# Packages setup
#-----------------------------------------------------------------------------------------
echo -e ""
read -ep "Use Telegram Notif      (yes/no) : " -i "no" tgnotif_install
SetConfigSetup tgnotif install $tgnotif_install
if [[ "${tgnotif_install,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Telegram Bot Key                 : " -i "" tgnotif_bot_key
    SetConfigSetup tgnotif bot_key $tgnotif_bot_key
    read -ep "Telegram User Chat ID            : " -i "" tgnotif_chat_id
    SetConfigSetup tgnotif bot_key $tgnotif_chat_id
fi

read -ep "Install Nginx Amplify   (yes/no) : " -i "no" amplify_install
SetConfigSetup nginx amplify $amplify_install
if [[ "${amplify_install,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Nginx Amplify API Key            : " -i "" amplify_api
    SetConfigSetup nginx api_key $amplify_api
fi

read -ep "Install Database Engine (yes/no) : " -i "yes" db_install
SetConfigSetup mysql install $db_install
if [[ "${db_install,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Database Engine  (mariadb/mysql) : " -i "mariadb" db_engine
    SetConfigSetup mysql engine $db_engine
    read -ep "Database Bind Address            : " -i "127.0.0.1" bind_address
    SetConfigSetup mysql bind_address $bind_address
    read -ep "Database Root Password           : "  -i "auto" root_pass
    if [[ "$root_pass" == "auto" ]] ; then
        SetConfigSetup mysql root_pass `pwgen -1 12`
    else
        SetConfigSetup mysql root_pass $root_pass
    fi
fi

read -ep "Install PostgreSQL      (yes/no) : " -i "no" pgsql_install
SetConfigSetup postgres install $pgsql_install
if [[ "${pgsql_install,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "PostgreSQL Root Password         : "  -i "auto" root_pass
    if [[ "$root_pass" == "auto" ]] ; then
        SetConfigSetup postgres root_pass `pwgen -1 12`
    else
        SetConfigSetup postgres root_pass $root_pass
    fi
fi

read -ep "Install NodeJS and Yarn (yes/no) : " -i "yes" nodejs_install
SetConfigSetup extras nodejs $nodejs_install

read -ep "Install PHP 7.2         (yes/no) : " -i "yes" php72_install
SetConfigSetup extras php72 $php72_install

read -ep "Install PHP 5.6         (yes/no) : " -i "yes" php56_install
SetConfigSetup extras php56 $php56_install

read -ep "Install python          (yes/no) : " -i "no" python_install
SetConfigSetup extras python $python_install

read -ep "Install IMAPSync        (yes/no) : " -i "yes" imapsync_install
SetConfigSetup extras imapsync $imapsync_install

read -ep "Install PowerDNS        (yes/no) : " -i "no" powerdns_install
SetConfigSetup powerdns install $powerdns_install

read -ep "Install FTP Server      (yes/no) : " -i "no" ftpserver_install
SetConfigSetup ftpserver install $powerdns_install

read -ep "Install Mail Server     (yes/no) : " -i "no" mailserver_install
SetConfigSetup mailserver install $powerdns_install

read -ep "Do you want to use Swap (yes/no) : " -i "no" swap_enable
SetConfigSetup swap enable $swap_enable
if [[ "${enabled,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Size of Swap (in megabyte)       : "  -i "2048" swap_size
    SetConfigSetup swap size $swap_size
fi

read -ep "Reboot after install    (yes/no) : " -i "no" reboot_after
SetConfigSetup system reboot $reboot_after

echo -e "" && read -p "Press enter to continue ..."

#-----------------------------------------------------------------------------------------
# Server configuration and install packages
#-----------------------------------------------------------------------------------------
source $ROOT/snippets/netconfig.sh
source $ROOT/installer/03-webserver.sh

InstallPackage swap enable $ROOT/snippets/swap.sh
InstallPackage extras nodejs $ROOT/installer/04-nodejs.sh
InstallPackage extras php72 $ROOT/installer/82-php72.sh
InstallPackage extras php56 $ROOT/installer/81-php56.sh
InstallPackage extras python $ROOT/installer/83-python.sh
InstallPackage extras python $ROOT/installer/83-python.sh
InstallPackage extras imapsync $ROOT/installer/86-imapsync.sh

# Setup MySQL / MariaDB
if [[ `crudini --get $ROOT/config.ini mysql install` == "yes" ]] ; then
    if [[ `crudini --get $ROOT/config.ini mysql engine` == "mariadb" ]] ; then
        source $ROOT/installer/02-mariadb.sh
    else
        source $ROOT/installer/85-mysql80.sh
    fi
fi

#-----------------------------------------------------------------------------------------
# Cleanup
#-----------------------------------------------------------------------------------------
apt -y autoremove && apt clean

if [[ `crudini --get $ROOT/config.ini system reboot` == "yes" ]] ; then
    shutdown -r now
else
    echo -e "\n" && netstat -pltn && echo -e "\n"
    echo -e "Server stack has been installed.\n"
    echo -e "Congratulation, you can reboot server now if you want...\n"
fi
