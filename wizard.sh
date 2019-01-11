#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

[ -z $ROOT ] && PWD=$(dirname "$(readlink -f "$0")") || PWD=$ROOT

# Functions
#-----------------------------------------------------------------------------------------

SetConfig() {
    crudini --set $PWD/config.ini $1 $2 $3
}

# Print welcome message
#-----------------------------------------------------------------------------------------
figlet "Are you ready?" ; echo -e "\n"
read -p "Press enter to continue ..."
echo

# Basic questions
#-----------------------------------------------------------------------------------------
CFVAL=`crudini --get "$PWD/config.ini" system ssh_port`
read -ep "Please specify SSH port                        : " -i "$CFVAL" ssh_port
SetConfig system ssh_port $ssh_port

CFVAL=`crudini --get $PWD/config.ini system timezone`
read -ep "Please specify time zone                       : " -i "$CFVAL" timezone
SetConfig system timezone $timezone

CFVAL=`crudini --get $PWD/config.ini system disable_ipv6`
read -ep "Do you want to disable IPv6?            yes/no : " -i "$CFVAL" disable_ipv6
SetConfig system disable_ipv6 $disable_ipv6

CFVAL=`crudini --get $PWD/config.ini telegram enable`
read -ep "Use Telegram Notif                      yes/no : " -i "$CFVAL" sshnotify
SetConfig telegram enable $sshnotify

if [[ "${sshnotify,,}" =~ ^(yes|y)$ ]] ; then
    BOTKEY=`crudini --get $PWD/config.ini telegram bot_key`
    CHATID=`crudini --get $PWD/config.ini telegram chat_id`
    read -ep "Telegram Bot Key                               : " -i "$BOTKEY" tg_bot_key
    read -ep "Telegram User Chat ID                          : " -i "$CHATID" tg_chat_id
    SetConfig telegram bot_key $tg_bot_key
    SetConfig telegram chat_id $tg_chat_id
fi

# Determine total memory for swap usage
#-----------------------------------------------------------------------------------------
memoryTotal=`grep MemTotal /proc/meminfo | awk '{print $2}'`
if (( $memoryTotal >= 2097152 )); then opsi="no"; else opsi="yes";fi

CFVAL=`crudini --get $PWD/config.ini system swap_enable`
read -ep "Do you want to use Swap ?               yes/no : " -i "$opsi" swap_enable
SetConfig system swap_enable $swap_enable

if [[ "${swap_enable,,}" =~ ^(yes|y)$ ]] ; then
    CFVAL=`crudini --get $PWD/config.ini system swap_size`
    read -ep "Enter size of Swap (in megabyte)               : "  -i "$CFVAL" swap_size
    SetConfig system swap_size $swap_size
fi

# Nginx + Amplify
#-----------------------------------------------------------------------------------------
CFVAL=`crudini --get $PWD/config.ini nginx amplify`
read -ep "Install Nginx Amplify ?                 yes/no : " -i "$CFVAL" amplify_install
SetConfig nginx amplify $amplify_install

if [[ "${amplify_install,,}" =~ ^(yes|y)$ ]] ; then
    CFVAL=`crudini --get $PWD/config.ini nginx api_key`
    read -ep "Nginx Amplify API Key                          : " -i "$CFVAL" amplify_api
    SetConfig nginx api_key $amplify_api
fi

# Interpreter packages
#-----------------------------------------------------------------------------------------
CFVAL=`crudini --get $PWD/config.ini nodejs install`
read -ep "Install NodeJS ?                        yes/no : " -i "$CFVAL" nodejs_install
SetConfig nodejs install $nodejs_install

if [[ "${nodejs_install,,}" =~ ^(yes|y)$ ]] ; then
    CFVAL=`crudini --get $PWD/config.ini nodejs yarn`
    read -ep "Install Yarn ?                          yes/no : " -i "$CFVAL" yarn_install
    SetConfig nodejs yarn $yarn_install
fi

CFVAL=`crudini --get $PWD/config.ini php php56`
read -ep "Install PHP 5.6 ?                       yes/no : " -i "$CFVAL" php56_install
SetConfig php php56 $php56_install

CFVAL=`crudini --get $PWD/config.ini php php72`
read -ep "Install PHP 7.2 ?                       yes/no : " -i "$CFVAL" php72_install
SetConfig php php72 $php72_install

CFVAL=`crudini --get $PWD/config.ini php php73`
read -ep "Install PHP 7.3 ?                       yes/no : " -i "$CFVAL" php73_install
SetConfig php php73 $php73_install

CFVAL=`crudini --get $PWD/config.ini php default`
read -ep "Default PHP version?             (5.6/7.2/7.3) : " -i "$CFVAL" php_default
SetConfig php default $php_default

CFVAL=`crudini --get $PWD/config.ini python default`
read -ep "Default Python version?            (2.7 / 3.5) : " -i "$CFVAL" python_default
SetConfig python default $python_default

# MySQL / MariDB server
#-----------------------------------------------------------------------------------------
CFVAL=`crudini --get $PWD/config.ini mysql install`
read -ep "Install MySQL or MariaDB server ?       yes/no : " -i "$CFVAL" mysql_install
SetConfig mysql install $mysql_install

if [[ "${mysql_install,,}" =~ ^(yes|y)$ ]] ; then

    CFVAL=`crudini --get $PWD/config.ini mysql bind_address`
    read -ep "Database Bind Address                          : " -i "$CFVAL" bind_address
    SetConfig mysql bind_address $bind_address

    CFVAL=`crudini --get $PWD/config.ini mysql root_pass`
    read -ep "Set database root password                     : "  -i "$CFVAL" root_pass
    if [[ "$root_pass" == "auto" ]] ; then
        SetConfig mysql root_pass `pwgen -1 12`
    else
        SetConfig mysql root_pass $root_pass
    fi

    CFVAL=`crudini --get $PWD/config.ini mysql engine`
    read -ep "Select database Engine         (mariadb/mysql) : " -i "$CFVAL" mysql_engine
    SetConfig mysql engine $mysql_engine

    if [[ "$mysql_engine" == "mysql" ]] ; then
        CFVAL=`crudini --get $PWD/config.ini mysql version`
        read -ep "Select MySQL version               (5.7 / 8.0) : " -i "$CFVAL" mysql_version
        SetConfig mysql version $mysql_version
    fi

fi

# PostgreSQL server
#-----------------------------------------------------------------------------------------
CFVAL=`crudini --get $PWD/config.ini postgres install`
read -ep "Install PostgreSQL database server ?    yes/no : " -i "$CFVAL" pgsql_install
SetConfig postgres install $pgsql_install

if [[ "${pgsql_install,,}" =~ ^(yes|y)$ ]] ; then

    CFVAL=`crudini --get $PWD/config.ini postgres bind_address`
    read -ep "Database Bind Address                          : " -i "$CFVAL" bind_address
    SetConfig postgres bind_address $bind_address

    CFVAL=`crudini --get $PWD/config.ini postgres root_pass`
    read -ep "Set database root password                     : "  -i "$CFVAL" root_pass
    if [[ "$root_pass" == "auto" ]] ; then
        SetConfig postgres root_pass `pwgen -1 12`
    else
        SetConfig postgres root_pass $root_pass
    fi

    CFVAL=`crudini --get $PWD/config.ini postgres version`
    read -ep "Select PostgreSQL version      (9.6 / 10 / 11) : " -i "$CFVAL" pgsql_version
    SetConfig postgres version $pgsql_version

fi

# Redis server
#-----------------------------------------------------------------------------------------
CFVAL=`crudini --get $PWD/config.ini redis install`
read -ep "Install Redis Server ?                  yes/no : " -i "$CFVAL" redis_install
SetConfig redis install $redis_install

# Reboot after installation finish
#-----------------------------------------------------------------------------------------
CFVAL=`crudini --get $PWD/config.ini system reboot`
read -ep "Reboot server after install             yes/no : " -i "$CFVAL" reboot_after
SetConfig system reboot $reboot_after

# Mark wizard as finish
#-----------------------------------------------------------------------------------------
crudini --set $PWD/config.ini 'setup' 'ready' 'yes'
