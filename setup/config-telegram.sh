#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PARENT=$(dirname `dirname $(readlink -f $0)`) || PARENT=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

# Telegram SSH Notification
#-----------------------------------------------------------------------------------------
SSH_PORT=`crudini --get $PARENT/config.ini system ssh_port`
TELEGRAM_NOTIFY=`crudini --get $PARENT/config.ini telegram enable`
TELEGRAM_BOTKEY=`crudini --get $PARENT/config.ini telegram bot_key`
TELEGRAM_CHATID=`crudini --get $PARENT/config.ini telegram chat_id`

sed -i "s/VAR_BOTKEY/$TELEGRAM_BOTKEY/" $PARENT/system/telegram.sh
sed -i "s/VAR_CHATID/$TELEGRAM_CHATID/" $PARENT/system/telegram.sh
cp $PARENT/system/telegram.sh /etc/profile.d/ ; chmod +x $_
