#!/bin/bash
# Copyright (C) 2018, Aris Ripandi.
# Author: Aris Ripandi <ripandi@pm.me>
#
# Purpose: Send realtime notification to Telegram
#  when user logged in via ssh.

BOT_KEY="VAR_BOTKEY"
CHAT_ID="VAR_CHATID"

if [[ ! -z $SSH_CONNECTION ]]; then

  CLIENT_IP="${SSH_CONNECTION%% *}"
  SERVER_IP=$(hostname -I | awk '{print $1}')
  USER_INFO="https://ipinfo.io/$CLIENT_IP"

  MESSAGE="*New remote SSH connection:*

User login : *$USER* @ *$(hostname -f)*
Date Time : *$(date "+%d %b %Y %T")*

Server IP : $SERVER_IP
Client IP : $CLIENT_IP

More information : [$USER_INFO]($USER_INFO)"

  API_URL="https://api.telegram.org/bot$BOT_KEY/sendMessage"

  curl -Lsd "chat_id=$CHAT_ID&text=$MESSAGE&disable_web_page_preview=true&parse_mode=markdown" $API_URL >/dev/null 2>&1

fi
