#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi


# Telegram Notification
read -e -p "Telegram notify    (y/n) : " -i "n" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
  read -e -p "Telegram Chat ID         : " -i "" tg_userid
  read -e -p "Telegram Bot Key         : " -i "" tg_userid
  cp $PWD/scripts/sshnotify /etc/profile.d/
  echo "USERID='$tg_userid'" > /etc/sshnotify.conf
  echo "BOTKEY='$tg_botkey'" >> /etc/sshnotify.conf
  chmod a+x /etc/profile.d/sshnotify
fi
