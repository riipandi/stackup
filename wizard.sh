#!/usr/bin/env bash

PWD=$(dirname "$(readlink -f "$0")")

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi


#-----------------------------------------------------------------------------------------
# Functions
#-----------------------------------------------------------------------------------------

SetConfigSetup() {
    crudini --set $ROOT/config.ini $1 $2 $3
}

#-----------------------------------------------------------------------------------------
# Ask the questions
#-----------------------------------------------------------------------------------------

# Change default repository mirror
read -ep "Change repository mirror?  yes/no : " -i "yes" changrepo
if [[ "${changrepo,,}" =~ ^(yes|y)$ ]] ; then source $ROOT/system/repository.sh ; fi

ChangeRootPass() {
    read -sp "Enter new root password           : " rootpass
    if [[ "$rootpass" == "" ]] ; then
        echo -e "" && ChangeRootPass
    else
        usermod root --password `openssl passwd -1 "$rootpass"`
    fi
}
read -ep "Change root password?      yes/no : " -i "no" changerootpass
if [[ "${changerootpass,,}" =~ ^(yes|y)$ ]] ; then ChangeRootPass ; fi

CreateNewUser() {
    while true; do
        echo
        read -sp "Enter new user password           : " userpass1
        [ "$userpass1" == "" ] && CreateNewUser
        echo
        read -sp "Enter new user password (again)   : " userpass2
        [ "$userpass1" = "$userpass2" ] && break
    done
    echo
}

read -ep "Create a new user?         yes/no : " -i "yes" createuser
if [[ "${createuser,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Enter new user fullname           : " -i "Admin Sistem" fullname
    read -ep "Enter new user username           : " -i "admin" username
    CreateNewUser
    useradd -mg sudo -s `which bash` $username -c "$fullname" -p `openssl passwd -1 "$userpass1"`
fi

# Upgrade basic system packages
source $ROOT/system/basicpkg.sh

# Determine country code for server location
country=`curl -s ipinfo.io | grep country | awk -F":" '{print $2}' | cut -d '"' -f2`
crudini --set $ROOT/config.ini 'system' 'country' $country

# Print welcome message
figlet "Are you ready?" && echo -e "\n"
read -p "Press enter to continue ..."

read -ep "Please specify SSH port                     : " -i "22" ssh_port
SetConfigSetup system ssh_port $ssh_port

read -ep "Please specify time zone                    : " -i "Asia/Jakarta" timezone
SetConfigSetup system timezone $timezone

read -ep "Disable IPv6                         yes/no : " -i "no" disable_ipv6
SetConfigSetup system disable_ipv6 $disable_ipv6

read -ep "Use Telegram Notif                   yes/no : " -i "no" tgnotif_install
SetConfigSetup tgnotif install $tgnotif_install
if [[ "${tgnotif_install,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Telegram Bot Key                            : " -i "" tgnotif_bot_key
    SetConfigSetup tgnotif bot_key $tgnotif_bot_key
    read -ep "Telegram User Chat ID                       : " -i "" tgnotif_chat_id
    SetConfigSetup tgnotif chat_id $tgnotif_chat_id
fi

read -ep "Install Nginx Amplify                yes/no : " -i "no" amplify_install
SetConfigSetup nginx amplify $amplify_install
if [[ "${amplify_install,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Nginx Amplify API Key                       : " -i "" amplify_api
    SetConfigSetup nginx api_key $amplify_api
fi

read -ep "Database Engine             (mariadb/mysql) : " -i "mariadb" db_engine
SetConfigSetup mysql engine $db_engine
read -ep "Database Bind Address                       : " -i "127.0.0.1" bind_address
SetConfigSetup mysql bind_address $bind_address
read -ep "Database Root Password                      : "  -i "auto" root_pass
if [[ "$root_pass" == "auto" ]] ; then
    SetConfigSetup mysql root_pass `pwgen -1 12`
else
    SetConfigSetup mysql root_pass $root_pass
fi

read -ep "Install PostgreSQL                   yes/no : " -i "no" pgsql_install
SetConfigSetup postgres install $pgsql_install
if [[ "${pgsql_install,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "PostgreSQL Root Password                    : "  -i "auto" root_pass
    if [[ "$root_pass" == "auto" ]] ; then
        SetConfigSetup postgres root_pass `pwgen -1 12`
    else
        SetConfigSetup postgres root_pass $root_pass
    fi
fi

read -ep "Install Redis Server                 yes/no : " -i "yes" redis_install
SetConfigSetup redis install $redis_install

# if [[ "${redis_install,,}" =~ ^(yes|y)$ ]] ; then
#     read -ep "Redis Server Password                       : "  -i "" redispass
#     if [[ "$redispass" != "" ]] ; then
#         SetConfigSetup redis password $redispass
#     fi
# fi

read -ep "Install NodeJS and Yarn              yes/no : " -i "yes" nodejs_install
SetConfigSetup extras nodejs $nodejs_install

read -ep "Install PHP 5.6                      yes/no : " -i "yes" php56_install
SetConfigSetup php php56 $php56_install

read -ep "Install PHP 7.2                      yes/no : " -i "yes" php72_install
SetConfigSetup php php72 $php72_install

read -ep "Install PHP 7.3                      yes/no : " -i "no" php73_install
SetConfigSetup php php73 $php73_install

read -ep "Default PHP ver?              (5.6/7.2/7.3) : " -i "7.2" php_default
SetConfigSetup php default $php_default

read -ep "Install python                       yes/no : " -i "yes" python_install
SetConfigSetup extras python $python_install

read -ep "Install IMAPSync                     yes/no : " -i "yes" imapsync_install
SetConfigSetup extras imapsync $imapsync_install

read -ep "Install PowerDNS                     yes/no : " -i "no" powerdns_install
SetConfigSetup powerdns install $powerdns_install

read -ep "Install FTP Server                   yes/no : " -i "no" ftpserver_install
SetConfigSetup ftpserver install $powerdns_install

read -ep "Install Mail Server                  yes/no : " -i "no" mailserver_install
SetConfigSetup mailserver install $powerdns_install

# Determine total memory
memoryTotal=`grep MemTotal /proc/meminfo | awk '{print $2}'`
if (( $memoryTotal >= 2097152 )); then opsi="no"; else opsi="yes";fi

read -ep "Do you want to use Swap              yes/no : " -i "$opsi" swap_enable
SetConfigSetup swap enable $swap_enable
if [[ "${enabled,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Size of Swap (in megabyte)                  : "  -i "2048" swap_size
    SetConfigSetup swap size $swap_size
fi

read -ep "Reboot after install                 yes/no : " -i "no" reboot_after
SetConfigSetup system reboot $reboot_after
