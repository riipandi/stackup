#!/bin/bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

apt update ; apt install -y sysfsutils redis-{server,tools}
echo 'kernel/mm/transparent_hugepage/enabled = never' > /etc/sysfs.conf
echo 'kernel/mm/transparent_hugepage/defrag = never' >> /etc/sysfs.conf
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag

crudini --set /etc/sysctl.conf '' 'vm.overcommit_memory' '1'
crudini --set /etc/sysctl.conf '' 'net.core.somaxconn' '512'
echo 512 > /proc/sys/net/core/somaxconn
mkdir -p /var/run/redis

sed -i "s/supervised no/supervised systemd/" /etc/redis/redis.conf
sed -i "s/# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/" /etc/redis/redis.conf
sed -i "s/# maxmemory <bytes>/maxmemory 256mb/" /etc/redis/redis.conf
sed -i "s|\("^bind" * *\).*|\1$(cat /tmp/db_bindaddr)|" /etc/redis/redis.conf
systemctl restart redis-server
