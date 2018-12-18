#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

api_key=`crudini --get $ROOT/config.ini nginx api_key`
db_pass=`crudini --get $ROOT/config.ini mysql root_pass`

API_KEY=$api_key bash <(curl -sLo- https://git.io/fNWVx)

crudini --set /etc/amplify-agent/agent.conf 'listener_syslog-default' '​address' '127.0.0.1:13579'
crudini --set /etc/amplify-agent/agent.conf 'mysql' 'unix_socket' '/var/run/mysqld/mysqld.sock'
crudini --set /etc/amplify-agent/agent.conf 'mysql' 'user' 'root'
crudini --set /etc/amplify-agent/agent.conf 'mysql' 'password' $db_pass
crudini --set /etc/amplify-agent/agent.conf 'credentials' 'hostname' `hostname -f`
crudini --set /etc/amplify-agent/agent.conf 'extensions' 'phpfpm' 'True'
crudini --set /etc/amplify-agent/agent.conf 'extensions' 'mysql' 'True'

mv /etc/nginx/conf.d/stub_status.{conf-disable,conf}

systemctl restart amplify-agent
