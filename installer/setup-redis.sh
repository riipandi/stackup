#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PWD=$(dirname `dirname $(readlink -f $0)`) || PWD=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

# Get configuration parameter
#-----------------------------------------------------------------------------------------
touch "$PWD/stackup.ini"
[[ $(cat "$PWD/stackup.ini" | grep -c "redis_bind_address") -eq 1 ]] && redis_bind_address=$(crudini --get $PWD/stackup.ini '' 'redis_bind_address')
[[ -z "$redis_bind_address" ]] && read -ep "Redis bind address ?                            : " -i "127.0.0.1" redis_bind_address

[[ $(cat "$PWD/stackup.ini" | grep -c "redis_max_memory") -eq 1 ]] && redis_max_memory=$(crudini --get $PWD/stackup.ini '' 'redis_max_memory')
[[ -z "$redis_max_memory" ]] && read -ep "Redis max memory (in megabyte) ?                : " -i "128" redis_max_memory

[[ $(cat "$PWD/stackup.ini" | grep -c "redis_password") -eq 1 ]] && redis_password=$(crudini --get $PWD/stackup.ini '' 'redis_password')
[[ -z "$redis_password" ]] && read -ep "Redis password ?                                : " -i "no" redis_password

[[ ! -d /var/run/redis ]] && mkdir -p /var/run/redis

apt update ; apt -y install sysfsutils redis-server redis-tools

sed -i "s/supervised no/supervised systemd/" /etc/redis/redis.conf
sed -i "s/# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/" /etc/redis/redis.conf
sed -i "s/# maxmemory <bytes>/maxmemory ${redis_max_memory}mb/" /etc/redis/redis.conf
sed -i "s|\("^bind" * *\).*|\1$redis_bind_address|" /etc/redis/redis.conf

# Securing redis-server with password
if ! [[ "${redis_password,,}" =~ ^(no|n)$ ]] ; then
    sed -i "s/# requirepass foobared/requirepass $redis_password/" /etc/redis/redis.conf
    echo "REDIS_PASSWORD:$redis_password" >> /usr/local/share/stackup.info
fi

systemctl restart redis-server
