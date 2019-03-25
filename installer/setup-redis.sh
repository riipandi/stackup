#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PARENT=$(dirname `dirname $(readlink -f $0)`) || PARENT=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

read -ep "Redis bind address ?                            : " -i "127.0.0.1" bind_address
read -ep "Redis password ?                                : " -i "no" redis_password
read -ep "Redis max memory (in megabyte) ?                : " -i "256mb" max_memory

[[ ! -d /var/run/redis ]] && mkdir -p /var/run/redis

apt update ; apt -y install sysfsutils redis-server redis-tools

sed -i "s/supervised no/supervised systemd/" /etc/redis/redis.conf
sed -i "s/# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/" /etc/redis/redis.conf
sed -i "s/# maxmemory <bytes>/maxmemory $max_memory/" /etc/redis/redis.conf
sed -i "s|\("^bind" * *\).*|\1$bind_address|" /etc/redis/redis.conf

# Securing redis-server with password
if ! [[ "${redis_password,,}" =~ ^(no|n)$ ]] ; then
    sed -i "s/# requirepass foobared/requirepass $redis_password/" /etc/redis/redis.conf
fi

systemctl restart redis-server
