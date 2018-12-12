#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

# Nginx Amplify
read -e -p "Install Amplify    (y/n) : " -i "n" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
  echo Yes > /tmp/install_amplify
  read -e -p "Nginx Amplify Key        : " -i "" amplify_key
  if [ "$amplify_key" != "" ] ;then
    echo $amplify_key > /tmp/amplify_key
  fi
fi

API_KEY=`cat /tmp/amplify_key` bash <(curl -sLo- https://git.io/fNWVx)
crudini --set /etc/amplify-agent/agent.conf 'listener_syslog-default' '​address' '127.0.0.1:13579'
crudini --set /etc/amplify-agent/agent.conf 'mysql' 'unix_socket' '/var/run/mysqld/mysqld.sock'
crudini --set /etc/amplify-agent/agent.conf 'mysql' 'user' 'root'
crudini --set /etc/amplify-agent/agent.conf 'mysql' 'password' `cat /tmp/rootdbpass`
crudini --set /etc/amplify-agent/agent.conf 'credentials' 'hostname' `hostname -f`
crudini --set /etc/amplify-agent/agent.conf 'extensions' 'phpfpm' 'True'
crudini --set /etc/amplify-agent/agent.conf 'extensions' 'mysql' 'True'
mv /etc/nginx/conf.d/stub_status.{conf-disable,conf}
systemctl restart amplify-agent
