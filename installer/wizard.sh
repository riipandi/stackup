#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PWD=$(dirname `dirname $(readlink -f $0)`) || PWD=$ROOT
#------------------------------------------------------------------------------
echo

# System setup
#-----------------------------------------------------------------------------------------
read -ep "Please specify SSH port                         : " -i "22" ssh_port
crudini --set $PWD/stackup.ini '' 'ssh_port' $ssh_port

read -ep "Please specify time zone                        : " -i "Asia/Jakarta" timezone
crudini --set $PWD/stackup.ini '' 'timezone' $timezone

read -ep "Do you want to disable IPv6 ?               y/n : " -i "n" disable_ipv6
crudini --set $PWD/stackup.ini '' 'disable_ipv6' $disable_ipv6

read -ep "Use Telegram ssh notification ?             y/n : " -i "n" answer
crudini --set $PWD/stackup.ini '' 'tgnotif_install' $answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Telegram Bot Key                                : " tg_bot_key
    read -ep "Telegram User Chat ID                           : " tg_chat_id
    crudini --set $PWD/stackup.ini '' 'tgnotif_bot_key' $tg_bot_key
    crudini --set $PWD/stackup.ini '' 'tgnotif_chat_id' $tg_chat_id
fi

# Linux SWAP
#-----------------------------------------------------------------------------------------
memoryTotal=`grep MemTotal /proc/meminfo | awk '{print $2}'`
if (( $memoryTotal >= 2097152 )); then opsi="n"; else opsi="y"; fi

read -ep "Do you want to use Swap ?                   y/n : " -i "$opsi" answer
crudini --set $PWD/stackup.ini '' 'swap_install' $answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Enter size of Swap (in megabyte)                : " -i "2048" swap_size
    crudini --set $PWD/stackup.ini '' 'swap_size' $swap_size
fi

# MySQL / MariaDB
#-----------------------------------------------------------------------------------------
echo && read -ep "Install MySQL / MariaDB ?                   y/n : " -i "y" answer
crudini --set $PWD/stackup.ini '' 'mysql_install' $answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Select database Engine          (mariadb/mysql) : " -i "mariadb" mysql_engine
    if [[ "$mysql_engine" == "mysql" ]] ; then
        read -ep "Select MySQL version                (5.7 / 8.0) : " -i "8.0" mysql_version
    else
        read -ep "Select MariaDB version            (10.3 / 10.4) : " -i "10.3" mysql_version
    fi
    read -ep "Database bind address                           : " -i "127.0.0.1" mysql_bind_address
    read -ep "Database listen port                            : " -i "3306" mysql_listen_port
    read -ep "Database root user                              : " -i "root" mysql_root_user
    read -ep "Database root password                          : " -i "auto" mysql_root_pass

    crudini --set $PWD/stackup.ini '' 'mysql_engine' $mysql_engine
    crudini --set $PWD/stackup.ini '' 'mysql_version' $mysql_version
    crudini --set $PWD/stackup.ini '' 'mysql_bind_address' $mysql_bind_address
    crudini --set $PWD/stackup.ini '' 'mysql_listen_port' $mysql_listen_port
    crudini --set $PWD/stackup.ini '' 'mysql_root_user' $mysql_root_user
    crudini --set $PWD/stackup.ini '' 'mysql_root_pass' $mysql_root_pass
fi

# PostgreSQL
#-----------------------------------------------------------------------------------------
echo && read -ep "Install PostgreSQL ?                        y/n : " -i "n" answer
crudini --set $PWD/stackup.ini '' 'pgsql_install' $answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Select PostgreSQL version?      (9.6 / 10 / 11) : " -i "10" pgsql_version
    read -ep "Database bind address                           : " -i "127.0.0.1" pgsql_bind_address
    read -ep "Database listen port                            : " -i "5432" pgsql_listen_port
    read -ep "Database root user                              : " -i "postgres" pgsql_root_user
    read -ep "Database root password                          : " -i "auto" pgsql_root_pass
    read -ep "Install pgAdmin4 utilities ?                y/n : " -i "y" pgadmin_install

    crudini --set $PWD/stackup.ini '' 'pgsql_version' $pgsql_version
    crudini --set $PWD/stackup.ini '' 'pgsql_bind_address' $pgsql_bind_address
    crudini --set $PWD/stackup.ini '' 'pgsql_listen_port' $pgsql_listen_port
    crudini --set $PWD/stackup.ini '' 'pgsql_root_user' $pgsql_root_user
    crudini --set $PWD/stackup.ini '' 'pgsql_root_pass' $pgsql_root_pass
    crudini --set $PWD/stackup.ini '' 'pgadmin_install' $pgadmin_install
fi

# Redis Server
#-----------------------------------------------------------------------------------------
echo && read -ep "Install Redis Server ?                      y/n : " -i "y" answer
crudini --set $PWD/stackup.ini '' 'redis_install' $answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Redis bind address ?                            : " -i "127.0.0.1" redis_bind_address
    read -ep "Redis max memory (in megabyte) ?                : " -i "128" redis_max_memory
    read -ep "Redis password ?                                : " -i "no" redis_password
    crudini --set $PWD/stackup.ini '' 'redis_bind_address' $redis_bind_address
    crudini --set $PWD/stackup.ini '' 'redis_max_memory' $redis_max_memory
    crudini --set $PWD/stackup.ini '' 'redis_password' $redis_password
fi

# Nginx + PHP + NodeJS
#-----------------------------------------------------------------------------------------
echo
read -ep "Install PHP 7.3 ?                           y/n : " -i "y" install_php_73
read -ep "Install PHP 7.2 ?                           y/n : " -i "y" install_php_72
read -ep "Install PHP 5.6 ?                           y/n : " -i "y" install_php_56
read -ep "Install NodeJS and Yarn ?                   y/n : " -i "y" install_nodejs
read -ep "Default PHP version ?                           : " -i "7.3" default_php

crudini --set $PWD/stackup.ini '' 'default_php' $default_php
crudini --set $PWD/stackup.ini '' 'install_php_73' $install_php_73
crudini --set $PWD/stackup.ini '' 'install_php_72' $install_php_72
crudini --set $PWD/stackup.ini '' 'install_php_56' $install_php_56
crudini --set $PWD/stackup.ini '' 'install_nodejs' $install_nodejs

read -ep "Do you want to use Nginx Amplify ?          y/n : " -i "n" answer
crudini --set $PWD/stackup.ini '' 'amplify_install' $answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Nginx Amplify Key                               : " amplify_key
    crudini --set $PWD/stackup.ini '' 'amplify_key' $amplify_key
fi

echo
