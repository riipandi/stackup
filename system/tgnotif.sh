#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

bot_key=`crudini --get $ROOT/config.ini tgnotif bot_key`
chat_id=`crudini --get $ROOT/config.ini tgnotif chat_id`

cp $PWD/snippets/sshnotify /etc/profile.d/

echo "USERID='$bot_key'" >  /etc/sshnotify.conf
echo "BOTKEY='$chat_id'" >> /etc/sshnotify.conf

chmod a+x /etc/profile.d/sshnotify
