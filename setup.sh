#!/usr/bin/env bash

ROOT=$(dirname "$(readlink -f "$0")")

# Check if this script running as root
if [[ $EUID -ne 0 ]]; then
    echo -e 'This script must be run as root' ; exit 1
else
    read -p "Press enter to continue ..."
fi

#-----------------------------------------------------------------------------------------
# Initial Setup
#-----------------------------------------------------------------------------------------
rm -f /etc/resolv.conf
echo 'nameserver 209.244.0.3' >  /etc/resolv.conf
echo 'nameserver 209.244.0.4' >> /etc/resolv.conf

# Upgrade basic system packages
source $ROOT/installer/00-repo.sh
apt update ; apt -y full-upgrade
apt -y autoremove ; apt clean
source $ROOT/installer/01-basepkg.sh

#-----------------------------------------------------------------------------------------
# User account
#-----------------------------------------------------------------------------------------
read -s -p "Enter new root password  : " rootpass
usermod root -p `openssl passwd -1 "$rootpass"`
echo -e ""
read -e -p "Enter new user fullname  : " -i "Admin Sistem" fullname
read -e -p "Enter new user username  : " -i "admin" username
read -s -p "Enter new user password  : " userpass
useradd -mg sudo -s `which bash` $username -c "$fullname" -p `openssl passwd -1 "$userpass"`
echo -e ""
read -e -p "Please specify SSH port  : " -i "22" ssh_port
echo $ssh_port > /tmp/ssh_port

read -e -p "Please specify time zone : " -i "Asia/Jakarta" timezone
echo $timezone > /tmp/timezone

read -e -p "Disable IPv6       (y/n) : " -i "n" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then echo No > /tmp/disable_ipv6 ;fi

read -e -p "Database Bind Address    : " -i "127.0.0.1" db_bindaddr
echo $db_bindaddr > /tmp/db_bindaddr

read -p "Press enter to continue ..."

#-----------------------------------------------------------------------------------------
# Basic server configuration
#-----------------------------------------------------------------------------------------
curl -s ipinfo.io | grep country | awk -F":" '{print $2}' | cut -d '"' -f2 > /tmp/country
source $ROOT/snippets/disable_ipv6.sh
source $ROOT/snippets/sysctl_cfg.sh
source $ROOT/snippets/netconfig.sh

#-----------------------------------------------------------------------------------------
# Setup wizard
#-----------------------------------------------------------------------------------------
compactInstall() {
    source $ROOT/02-mariadb.sh
    source $ROOT/03-webserver.sh
    source $ROOT/92-ngamplify.sh
    source $ROOT/telegramnotif.sh
}

fullInstall() {
    compactInstall
    source $ROOT/ngamplify.sh
    source $ROOT/telegramnotif.sh
}

# Ask the questions
setupMenu() {
    echo -e "1 : Full installation     [all packages will be installed]"
    echo -e "2 : Compact installation  [nginx, php, mariadb, nodejs, yarn]"
    echo -e "3 : Custom installation   [it's according to your choice]\n"

    read -e -p "Choose components  (1/2/3) : " -i "1" answer
    if [ $answer == 1 ] ;then
        fullInstall
    elif [ $answer == 2 ] ;then
        compactInstall
    elif [ $answer == 3 ] ;then
        source $ROOT/custom.sh
    elif ! [[ $answer =~ ^[1-3]+$ ]] ;then
        clear &&  echo -e "Please choose the right option!"
        setupMenu
    fi
}
clear && setupMenu

#-----------------------------------------------------------------------------------------
# Cleanup
#-----------------------------------------------------------------------------------------
apt -y autoremove

echo -e "\n" && netstat -pltn && echo -e "\n"
echo -e "Server stack has been installed.\n"
echo -e "DB Root Password : `cat /tmp/rootdbpass`\n"

echo -e "Congratulation, you can reboot server now if you want.."
# read -e -p "Reboot the server    y/n : " -i "n" answer
# if [ "$answer" != "${answer#[Yy]}" ] ;then shutdown -r now ; fi
