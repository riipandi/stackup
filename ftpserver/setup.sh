#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

#-----------------------------------------------------------------------------------------
# Install ProFTPd
#-----------------------------------------------------------------------------------------

debconf-set-selections <<< "iptables-persistent iptables-persistent/autosave_v4 boolean true"
debconf-set-selections <<< "iptables-persistent iptables-persistent/autosave_v6 boolean true"
apt update ; apt -y install proftpd-mod-mysql iptables iptables-persistent

#-----------------------------------------------------------------------------------------
# Configure ProFTPd
#-----------------------------------------------------------------------------------------
[[ $(cat /etc/group | grep -c ftpgroup) -eq 1 ]] || groupadd -g 2001 ftpgroup
[[ $(cat /etc/passwd | grep -c ftpuser) -eq 1 ]] || useradd -u 2001 -s /bin/false -d /bin/null -g ftpgroup ftpuser

iptables -A INPUT -p tcp -m tcp --dport 50000:50100 -j ACCEPT
netfilter-persistent save
netfilter-persistent reload

openssl req -x509 -nodes -days 365 -newkey rsa:3072 \
 -keyout /etc/ssl/private/proftpd.key \
 -out /etc/ssl/certs/proftpd.crt -subj "/CN=$(hostname -f)"

chmod 0600 /etc/ssl/private/proftpd.key
chmod 0640 /etc/ssl/private/proftpd.key

rm -fr /etc/proftpd/*
cp -r $PWD/ftpserver/config/* /etc/proftpd/.
chown -R root: /etc/proftpd

sed -i "s/DB_NAME/$(cat /tmp/ecp_dbname)/"  /etc/proftpd/conf.d/sql.conf
sed -i "s/DB_PASS/$(cat /tmp/ecp_dbpass)/"  /etc/proftpd/conf.d/sql.conf
sed -i "s/DB_HOST/$(cat /tmp/db_bindaddr)/" /etc/proftpd/conf.d/sql.conf

systemctl restart proftpd
