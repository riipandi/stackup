#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

PWD=$(dirname "$(readlink -f "$0")")
PARENT=$(dirname "$PWD")


# Get parameter
#-----------------------------------------------------------------------------------------
ROOT_PASS=`crudini --get $PARENT/config.ini redis password`
BIND_ADDR=`crudini --get $PARENT/config.ini mysql bind_address`

# Install packages
#-----------------------------------------------------------------------------------------

mkdir -p /var/run/redis

apt update -qq ; apt install -y sysfsutils redis-{server,tools}

sed -i "s/supervised no/supervised systemd/" /etc/redis/redis.conf
sed -i "s/# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/" /etc/redis/redis.conf
sed -i "s/# maxmemory <bytes>/maxmemory 256mb/" /etc/redis/redis.conf
sed -i "s|\("^bind" * *\).*|\1$BIND_ADDR|" /etc/redis/redis.conf

# Securing redis-server with password
if [[ $PARENT_PASS != "no"]] ; then
    sed -i "s/# requirepass foobared/requirepass $PARENT_PASS/" /etc/redis/redis.conf
fi

systemctl restart redis-server
