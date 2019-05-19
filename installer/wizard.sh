#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PWD=$(dirname `dirname $(readlink -f $0)`) || PWD=$ROOT
#------------------------------------------------------------------------------

read -ep "Use Telegram ssh notification ?             y/n : " -i "n" answer
crudini --set $PWD/stackup.ini 'telegram_notification' 'install' $answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Telegram Bot Key                                : " tg_bot_key
    read -ep "Telegram User Chat ID                           : " tg_chat_id
    crudini --set $PWD/stackup.ini 'telegram_notification' 'bot_key' $tg_bot_key
    crudini --set $PWD/stackup.ini 'telegram_notification' 'chat_id' $tg_chat_id
fi

read -ep "Please specify SSH port                         : " -i "22" ssh_port
crudini --set $PWD/stackup.ini 'setup' 'ssh_port' $ssh_port

read -ep "Please specify time zone                        : " -i "Asia/Jakarta" timezone
crudini --set $PWD/stackup.ini 'setup' 'timezone' $timezone

read -ep "Do you want to disable IPv6?                y/n : " -i "n" disable_ipv6
crudini --set $PWD/stackup.ini 'setup' 'disable_ipv6' $disable_ipv6
