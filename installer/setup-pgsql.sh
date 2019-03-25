#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PARENT=$(dirname `dirname $(readlink -f $0)`) || PARENT=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

read -ep "Select PostgreSQL version?      (9.6 / 10 / 11) : " -i "10" pgsql_version
read -ep "Database bind address                           : " -i "127.0.0.1" pgsql_bind_address
read -ep "Database listen port                            : " -i "5432" pgsql_listen_port
read -ep "Database root user                              : " -i "postgres" pgsql_root_user
read -ep "Database root password                          : " -i "auto" pgsql_root_pass

if [[ "$pgsql_root_pass" == "auto" ]] ; then
    DB_ROOT_PASS=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-25)
else
    DB_ROOT_PASS=$pgsql_root_pass
fi

echo "deb https://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" > /etc/apt/sources.list.d/pgdg.list
curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && apt update

if [ $pgsql_version == "9.6" ] ; then apt install -y postgresql-{9.6,client-9.6,contrib-9.6} ; fi
if [ $pgsql_version == "10" ] ; then apt install -y postgresql-{10,client-10} ; fi
if [ $pgsql_version == "11" ] ; then apt install -y postgresql-{11,client-11} ; fi

systemctl restart postgresql

sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$DB_ROOT_PASS'"
