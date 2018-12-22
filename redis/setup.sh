#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

apt update -qq ; apt install -y sysfsutils redis-{server,tools}

if [[ $(cat /etc/sysfs.conf | grep -c "transparent_hugepage") -eq 0 ]]; then

    echo 'kernel/mm/transparent_hugepage/enabled = never' > /etc/sysfs.conf
    echo 'kernel/mm/transparent_hugepage/defrag = never' >> /etc/sysfs.conf

fi

echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag

crudini --set /etc/sysctl.conf '' 'vm.overcommit_memory' '1'
crudini --set /etc/sysctl.conf '' 'net.core.somaxconn' '512'
echo 512 > /proc/sys/net/core/somaxconn

mkdir -p /var/run/redis

bindaddress=`crudini --get $ROOT/config.ini redis bind_address`

sed -i "s/supervised no/supervised systemd/" /etc/redis/redis.conf
sed -i "s/# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/" /etc/redis/redis.conf
sed -i "s/# maxmemory <bytes>/maxmemory 256mb/" /etc/redis/redis.conf
sed -i "s|\("^bind" * *\).*|\1$bindaddress|" /etc/redis/redis.conf


# Securing redis-server with password
# sed -i "s/# requirepass foobared/requirepass $(echo "redisspass" | openssl base64 -A)/" /etc/redis/redis.conf

systemctl restart redis-server
