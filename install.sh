#!/usr/bin/env bash

ROOT=$(dirname "$(readlink -f "$0")")

# Check if this script running as root
if [[ $EUID -ne 0 ]]; then
    echo -e 'This script must be run as root' ; exit 1
else
    read -p "Press enter to continue ..."
fi

source $ROOT/snippets/helpers.sh

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

read -s -p "Enter new root password          : " rootpass
SetConfigSetup system rootpass `openssl passwd -1 "$rootpass"`

echo -e ""
read -e -p "Enter new user fullname          : " -i "Admin Sistem" fullname
SetConfigSetup system fullname $fullname

read -e -p "Enter new user username          : " -i "admin" username
SetConfigSetup system username $username

read -s -p "Enter new user password          : " userpass
SetConfigSetup system userpass `openssl passwd -1 "$userpass"`

echo -e ""
read -e -p "Please specify SSH port          : " -i "22" ssh_port
SetConfigSetup system ssh_port $ssh_port

read -e -p "Please specify time zone         : " -i "Asia/Jakarta" timezone
SetConfigSetup system timezone $timezone

read -e -p "Disable IPv6            (yes/no) : " -i "no" disable_ipv6
SetConfigSetup system disable_ipv6 $disable_ipv6

#-----------------------------------------------------------------------------------------
# Packages setup
#-----------------------------------------------------------------------------------------
echo -e ""
read -e -p "Use Telegram Notif      (yes/no) : " -i "no" tgnotif_install
SetConfigSetup tgnotif install $tgnotif_install
if [[ "${tgnotif_install,,}" =~ ^(yes|y)$ ]] ; then
    read -e -p "Telegram Bot Key                 : " -i "" tgnotif_bot_key
    SetConfigSetup tgnotif bot_key $tgnotif_bot_key
    read -e -p "Telegram User Chat ID            : " -i "" tgnotif_chat_id
    SetConfigSetup tgnotif bot_key $tgnotif_chat_id
fi

read -e -p "Install Nginx Amplify   (yes/no) : " -i "no" amplify_install
SetConfigSetup nginx amplify $amplify_install
if [[ "${amplify_install,,}" =~ ^(yes|y)$ ]] ; then
    read -e -p "Nginx Amplify API Key            : " -i "" amplify_api
    SetConfigSetup nginx api_key $amplify_api
fi

read -e -p "Install Database Engine (yes/no) : " -i "yes" db_install
SetConfigSetup mysql install $db_install
if [[ "${db_install,,}" =~ ^(yes|y)$ ]] ; then
    read -e -p "Database Engine  (mariadb/mysql) : " -i "mariadb" db_engine
    SetConfigSetup mysql engine $db_engine
    read -e -p "Database Bind Address            : " -i "127.0.0.1" bind_address
    SetConfigSetup mysql bind_address $bind_address
    read -e -p "Database Root Password           : "  -i "auto" root_pass
    if [[ "$root_pass" == "auto" ]] ; then
        SetConfigSetup mysql root_pass `pwgen -1 12`
    else
        SetConfigSetup mysql root_pass $root_pass
    fi
fi

read -e -p "Install PostgreSQL      (yes/no) : " -i "no" pgsql_install
SetConfigSetup postgres install $pgsql_install
if [[ "${pgsql_install,,}" =~ ^(yes|y)$ ]] ; then
    read -e -p "PostgreSQL Root Password         : "  -i "auto" root_pass
    if [[ "$root_pass" == "auto" ]] ; then
        SetConfigSetup postgres root_pass `pwgen -1 12`
    else
        SetConfigSetup postgres root_pass $root_pass
    fi
fi

read -e -p "Install NodeJS and Yarn (yes/no) : " -i "yes" nodejs_install
SetConfigSetup extras nodejs $nodejs_install

read -e -p "Install PHP 7.2         (yes/no) : " -i "no" php72_install
SetConfigSetup extras php72 $php72_install

read -e -p "Install PHP 5.6         (yes/no) : " -i "no" php56_install
SetConfigSetup extras php56 $php56_install

read -e -p "Install Python3         (yes/no) : " -i "no" python_install
SetConfigSetup extras python3 $python_install

read -e -p "Install IMAPSync        (yes/no) : " -i "no" imapsync_install
SetConfigSetup extras imapsync $imapsync_install

read -e -p "Install PowerDNS        (yes/no) : " -i "no" powerdns_install
SetConfigSetup powerdns install $powerdns_install

read -e -p "Install FTP Server      (yes/no) : " -i "no" ftpserver_install
SetConfigSetup ftpserver install $powerdns_install

read -e -p "Install Mail Server     (yes/no) : " -i "no" mailserver_install
SetConfigSetup mailserver install $powerdns_install

read -e -p "Reboot after install    (yes/no) : " -i "no" reboot_after
SetConfigSetup system reboot $reboot_after

echo -e "" && read -p "Press enter to continue ..."

#-----------------------------------------------------------------------------------------
# Basic server configuration
#-----------------------------------------------------------------------------------------
source $ROOT/snippets/netconfig.sh

#-----------------------------------------------------------------------------------------
# Cleanup
#-----------------------------------------------------------------------------------------
apt -y autoremove && apt clean

if [[ `crudini --get $ROOT/install.ini system reboot` == "yes" ]] ; then
    shutdown -r now
else
    echo -e "\n" && netstat -pltn && echo -e "\n"
    echo -e "Server stack has been installed.\n"
    echo -e "Congratulation, you can reboot server now if you want...\n"
fi
