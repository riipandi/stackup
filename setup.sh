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
chattr +i /etc/resolv.conf

# Upgrade basic system packages
source $ROOT/installer/repositories.sh
apt update ; apt -y full-upgrade
apt -y autoremove ; apt clean

# Install basic packages
source $ROOT/installer/basepkg.sh

# Get Country Code
curl -s ipinfo.io | grep country | awk -F":" '{print $2}' | cut -d '"' -f2 > /tmp/country

#-----------------------------------------------------------------------------------------
# User account
#-----------------------------------------------------------------------------------------
read -s -p "Enter new root password  : " rootpass
usermod root -p `openssl passwd -1 "$rootpass"`

echo -e "\n"
read -e -p "Enter new user fullname  : " -i "Admin Sistem" fullname
read -e -p "Enter new user username  : " -i "admin" username
read -s -p "Enter new user password  : " userpass
useradd -mg sudo -s `which bash` $username -c "$fullname" -p `openssl passwd -1 "$userpass"`

echo -e "\n"
read -e -p "Please specify SSH port  : " -i "22" ssh_port
echo $ssh_port > /tmp/ssh_port

echo -e "\n"
read -e -p "Please specify time zone : " -i "Asia/Jakarta" timezone
echo $timezone > /tmp/timezone

read -e -p "Disable IPv6       (y/n) : " -i "n" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then echo No > /tmp/disable_ipv6 ;fi

echo -e "\n"
read -e -p "Database Bind Address    : " -i "127.0.0.1" db_bindaddr
echo $db_bindaddr > /tmp/db_bindaddr

#-----------------------------------------------------------------------------------------
# Basic server configuration
#-----------------------------------------------------------------------------------------
if [ "`cat /tmp/country`" != "ID" ] || [ "`cat /tmp/country`" != "SG" ] ; then
    ntpdate -u pool.ntp.org
else
    ntpdate -u 0.asia.pool.ntp.org
fi

# SSH Server
perl -pi -e 's#(.*sudo.*ALL=)(.*)#${1}(ALL) NOPASSWD:ALL#' /etc/sudoers
sed -i "s|\("^PubkeyAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ClientAliveInterval" * *\).*|\1600|" /etc/ssh/sshd_config
sed -i "s|\("^AllowTcpForwarding" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ClientAliveCountMax" * *\).*|\13|" /etc/ssh/sshd_config
sed -i "s|\("^ListenAddress" * *\).*|\10.0.0.0|" /etc/ssh/sshd_config
sed -i "s|\("^PermitRootLogin" * *\).*|\1no|" /etc/ssh/sshd_config
sed -i "s|\("^PermitTunnel" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^StrictModes" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s/[#]*ListenAddress/ListenAddress/" /etc/ssh/sshd_config
sed -i "s/[#]*Port [0-9]*/Port $(cat /tmp/ssh_port)/" /etc/ssh/sshd_config
sed -i "s/ListenAddress :://" /etc/ssh/sshd_config
timedatectl set-timezone `cat /tmp/timezone`
figlet `hostname -s` > /etc/motd
systemctl restart ssh

# Sysctl configuration
crudini --set /etc/sysctl.conf '' 'net.ipv4.ip_forward'   '1'
crudini --set /etc/sysctl.conf '' 'vm.vfs_cache_pressure' '50'
crudini --set /etc/sysctl.conf '' 'vm.swappiness'         '10'
sysctl -p

# Disable IPv6
if [ "`cat /tmp/disable_ipv6`" == "Yes" ] ;then
    sed -i "s/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/" /etc/gai.conf
    crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.all.disable_ipv6'     '1'
    crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.default.disable_ipv6' '1'
    crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.lo.disable_ipv6'      '1'
    echo -e 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
    sysctl -p
fi

#-----------------------------------------------------------------------------------------
# Setup wizard
#-----------------------------------------------------------------------------------------

setupCP() {
    PMA_DIR="/var/www/myadmin"
    echo "ecp_`pwgen -1 -A 8`" > /tmp/ecp_dbname
    echo `pwgen -1 12` > /tmp/ecp_dbpass

    CP_DB_NAME=`cat /tmp/ecp_dbname`
    CP_DB_PASS=`cat /tmp/ecp_dbpass`
    DB_BINDADR=`cat /tmp/db_bindaddr`

    mysql -uroot -p"`cat /tmp/ecp_dbpass`" -e "CREATE DATABASE IF NOT EXISTS `cat /tmp/ecp_dbname`"
    mysql -uroot -p"`cat /tmp/ecp_dbpass`" -e "CREATE USER IF NOT EXISTS '$CP_DB_NAME'@'$DB_BINDADR' IDENTIFIED BY '$CP_DB_PASS'"
    mysql -uroot -p"`cat /tmp/ecp_dbpass`" -e "GRANT ALL PRIVILEGES ON $CP_DB_NAME.* TO '$CP_DB_NAME'@'$DB_BINDADR'"
    mysql -uroot -p"`cat /tmp/ecp_dbpass`" -e "FLUSH PRIVILEGES"
    mysql -uroot -p"`cat /tmp/ecp_dbpass`" `cat /tmp/ecp_dbname` < $ROOT/dbschema.sql
    perl -pi -e 's#(.*host.*= )(.*)#${1}"'`cat /tmp/db_bindaddr`'";#' $PMA_DIR/config.inc.php
}

customInstall() {
    source $ROOT/custom.sh
}

compactInstall() {
    source $ROOT/webserver.sh
    source $ROOT/ngamplify.sh
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
        customInstall
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
echo -e "Control Panel DB : `cat /tmp/ecp_dbname`"
echo -e "DB Root Password : `cat /tmp/ecp_dbpass`\n"

echo -e "Congratulation, you can reboot server now if you want.."
# read -e -p "Reboot the server    y/n : " -i "n" answer
# if [ "$answer" != "${answer#[Yy]}" ] ;then shutdown -r now ; fi
