#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PARENT=$(dirname `dirname $(readlink -f $0)`) || PARENT=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

# Telegram SSH Notification
#-----------------------------------------------------------------------------------------
read -ep "Use Telegram ssh notification ?             y/n : " -i "n" answer

if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then

    read -ep "Telegram Bot Key                                : " tg_bot_key
    read -ep "Telegram User Chat ID                           : " tg_chat_id

    sed -i "s/VAR_BOTKEY/$tg_bot_key/" $PARENT/config/tg-notif.sh
    sed -i "s/VAR_CHATID/$tg_chat_id/" $PARENT/config/tg-notif.sh
    cp $PARENT/config/tg-notif.sh /etc/profile.d/ ; chmod +x $_
fi
