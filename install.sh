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

countdown()
(
    IFS=:
    set -- $*
    secs=$(( ${1#0} * 3600 + ${2#0} * 60 + ${3#0} ))
    while [ $secs -gt 0 ] ; do
        sleep 1 &
        printf "\r%02d:%02d:%02d" $((secs/3600)) $(( (secs/60)%60)) $((secs%60))
        secs=$(( $secs - 1 ))
        wait
    done
    echo
)

#-----------------------------------------------------------------------------------------
# Initial Setup
#-----------------------------------------------------------------------------------------
rm -f /etc/resolv.conf
echo 'nameserver 209.244.0.3' >  /etc/resolv.conf
echo 'nameserver 209.244.0.4' >> /etc/resolv.conf

# Upgrade basic system packages
read -ep "Change default repository mirror?  yes/no : " -i "yes" changrepo
if [[ "${changrepo,,}" =~ ^(yes|y)$ ]] ; then source $ROOT/system/repository.sh ; fi
source $ROOT/system/basicpkg.sh

figlet "Hello there!"
read -p "Press enter to continue ..."
echo ""

#-----------------------------------------------------------------------------------------
# System setup
#-----------------------------------------------------------------------------------------
SetConfigSetup system country `curl -s ipinfo.io | grep country | awk -F":" '{print $2}' | cut -d '"' -f2`

ChangeRootPass() {
    read -sp "Enter new root password          : " rootpass
    if [[ "$rootpass" == "" ]] ; then
        echo -e "" && ChangeRootPass
    else
        usermod root --password `openssl passwd -1 "$rootpass"`
    fi
}
ChangeRootPass

echo -e ""
read -ep "Enter new user fullname          : " -i "Admin Sistem" fullname
read -ep "Enter new user username          : " -i "admin" username

ChangeUserPass() {
    read -sp "Enter new user password          : " userpass
    if [[ "$userpass" == "" ]] ; then
        echo -e "" && ChangeUserPass
    else
        useradd -mg sudo -s `which bash` $username -c "$fullname" -p `openssl passwd -1 "$userpass"`
    fi
}
ChangeUserPass

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

read -ep "Install PHP 7.3         (yes/no) : " -i "yes" php73_install
SetConfigSetup extras php73 $php73_install

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
InstallPackage swap enable $ROOT/system/swap.sh

InstallPackage tgnotif install $ROOT/system/tgnotif.sh
source $ROOT/system/netconfig.sh

source $ROOT/php/setup72.sh
InstallPackage extras php73 $ROOT/php/setup73.sh
InstallPackage extras php56 $ROOT/php/setup56.sh
source $ROOT/php/configure.sh

source $ROOT/nginx/setup.sh
source $ROOT/nginx/phpmy.sh
InstallPackage nginx amplify $ROOT/nginx/amplify.sh

# Setup MySQL / MariaDB Database
if [[ `crudini --get $ROOT/config.ini mysql engine` == "mariadb" ]] ; then
    source $ROOT/mysql/mariadb.sh
    source $ROOT/mysql/configure.sh
else
    source $ROOT/mysql/mysql80.sh
fi

InstallPackage postgres install $ROOT/postgres/setup.sh
InstallPackage extras nodejs $ROOT/nodejs/setup.sh
InstallPackage extras python $ROOT/python/setup.sh

# InstallPackage powerdns install $ROOT/powerdns/setup.sh
InstallPackage mailserver install $ROOT/mailsuite/mailserver.sh
InstallPackage extras imapsync $ROOT/mailsuite/imapsync.sh

#-----------------------------------------------------------------------------------------
# Cleanup
#-----------------------------------------------------------------------------------------
cp $ROOT/snippets/fix-permission /usr/local/bin/fix-permission
cp $ROOT/snippets/vhost-create /usr/local/bin/vhost-create

echo "" && apt -y autoremove && apt clean && netstat -pltn

echo -e "\nCongratulation, server stack has been installed.\n"

if [[ `crudini --get $ROOT/config.ini system reboot` == "yes" ]] ; then
    echo "System will reboot in:"
    countdown "00:00:05" ; shutdown -r now
fi
