#!/bin/bash

PWD=$(dirname "$(readlink -f "$0")")
PARENT=$(dirname $PWD)

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi


#-----------------------------------------------------------------------------------------
# Setup PostgreSQL
#-----------------------------------------------------------------------------------------

curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
echo "deb https://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" > /etc/apt/sources.list.d/pgsql.list

apt update ; apt -y install postgresql-{10,client-10}

sudo -u postgres psql -c "ALTER USER postgres PASSWORD '`cat /tmp/db_bindaddr`'"
