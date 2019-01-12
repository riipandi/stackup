#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

[ -z $ROOT ] && PARENT=$(dirname "$(readlink -f "$0")") || PARENT=$ROOT

# Get parameter
#-----------------------------------------------------------------------------------------
ROOT_USER="postgres"
ROOT_PASS=`crudini --get $PARENT/config.ini postgres root_pass`
BIND_ADDR=`crudini --get $PARENT/config.ini postgres bind_address`
PGVERSION=`crudini --get $PARENT/config.ini postgres version`

# Install and configure packages
#-----------------------------------------------------------------------------------------

echo "deb https://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" > /etc/apt/sources.list.d/pgdg.list
curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && apt update

if [ $PGVERSION == "9.6" ] ; then apt install -y postgresql-{9.6,client-9.6,contrib-9.6} ; fi
if [ $PGVERSION == "10" ] ; then apt install -y postgresql-{10,client-10} ; fi
if [ $PGVERSION == "11" ] ; then apt install -y postgresql-{11,client-11} ; fi

systemctl restart postgresql

sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$ROOT_PASS'"
