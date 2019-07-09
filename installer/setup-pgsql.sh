#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PWD=$(dirname `dirname $(readlink -f $0)`) || PWD=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

# Get configuration parameter
#-----------------------------------------------------------------------------------------
touch "$PWD/stackup.ini"
[[ $(cat "$PWD/stackup.ini" | grep -c "pgsql_version") -eq 1 ]] && pgsql_version=$(crudini --get $PWD/stackup.ini '' 'pgsql_version')
[[ -z "$pgsql_version" ]] && read -ep "Select PostgreSQL version?      (9.6 / 10 / 11) : " -i "10" pgsql_version

[[ $(cat "$PWD/stackup.ini" | grep -c "pgsql_bind_address") -eq 1 ]] && pgsql_bind_address=$(crudini --get $PWD/stackup.ini '' 'pgsql_bind_address')
[[ -z "$pgsql_bind_address" ]] && read -ep "Database bind address                           : " -i "127.0.0.1" pgsql_bind_address

[[ $(cat "$PWD/stackup.ini" | grep -c "pgsql_listen_port") -eq 1 ]] && pgsql_listen_port=$(crudini --get $PWD/stackup.ini '' 'pgsql_listen_port')
[[ -z "$pgsql_listen_port" ]] && read -ep "Database listen port                            : " -i "3306" pgsql_listen_port

[[ $(cat "$PWD/stackup.ini" | grep -c "pgsql_root_user") -eq 1 ]] && pgsql_root_user=$(crudini --get $PWD/stackup.ini '' 'pgsql_root_user')
[[ -z "$pgsql_root_user" ]] && read -ep "Database root user                              : " -i "root" pgsql_root_user

[[ $(cat "$PWD/stackup.ini" | grep -c "pgsql_root_pass") -eq 1 ]] && pgsql_root_pass=$(crudini --get $PWD/stackup.ini '' 'pgsql_root_pass')
[[ -z "$pgsql_root_pass" ]] && read -ep "Database root password                          : " -i "auto" pgsql_root_pass

if [[ "$pgsql_root_pass" == "auto" ]] ; then
    DB_ROOT_PASS=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-25)
    echo "PGQL_ROOT_PASS = $DB_ROOT_PASS" >> /root/server.info
else
    DB_ROOT_PASS=$pgsql_root_pass
fi

echo "deb https://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" > /etc/apt/sources.list.d/pgdg.list
curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && apt update

if [ $pgsql_version == "9.6" ] ; then apt install -y postgresql-{9.6,client-9.6,contrib-9.6} ; fi
if [ $pgsql_version == "10" ] ; then apt install -y postgresql-{10,client-10} ; fi
if [ $pgsql_version == "11" ] ; then apt install -y postgresql-{11,client-11} ; fi

sed -i "s/[#]*listen_addresses/listen_addresses/" /etc/postgresql/${pgsql_version}/main/postgresql.conf
sed -i "s|\("^listen_addresses" * *\).*|\1='127.0.0.1'|" /etc/postgresql/${pgsql_version}/main/postgresql.conf

systemctl restart postgresql

sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$DB_ROOT_PASS'"
