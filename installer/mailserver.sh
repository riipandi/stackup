#!/bin/bash

PWD=$(dirname "$(readlink -f "$0")")
PARENT=$(dirname $PWD)

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

apt update ; apt -y install postfix postfix-mysql ; systemctl enable --now postfix

postconf virtual_mailbox_domains=mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
postconf virtual_mailbox_maps=mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
postconf virtual_alias_domains=mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
postconf virtual_alias_maps=mysql:/etc/postfix/mysql-virtual-alias-maps.cf,mysql:/etc/postfix/mysql-email2email.cf

cat > /etc/postfix/mysql-virtual-mailbox-domains.cf <<EOF
hosts = `cat /tmp/db_bindaddr`
dbname = `cat /tmp/ecp_dbname`
user = `cat /tmp/ecp_dbname`
password = `cat /tmp/ecp_dbpass`
query = SELECT 1 FROM domains WHERE name='%s'
EOF

cat > /etc/postfix/mysql-virtual-mailbox-maps.cf <<EOF
hosts = `cat /tmp/db_bindaddr`
dbname = `cat /tmp/ecp_dbname`
user = `cat /tmp/ecp_dbname`
password = `cat /tmp/ecp_dbpass`
query = SELECT 1 FROM mail_users WHERE email='%s'
EOF

cat > /etc/postfix/mysql-virtual-alias-maps.cf <<EOF
hosts = `cat /tmp/db_bindaddr`
dbname = `cat /tmp/ecp_dbname`
user = `cat /tmp/ecp_dbname`
password = `cat /tmp/ecp_dbpass`
query = SELECT destination FROM mail_aliases WHERE source='%s'
EOF

cat > /etc/postfix/mysql-email2email.cf <<EOF
hosts = `cat /tmp/db_bindaddr`
dbname = `cat /tmp/ecp_dbname`
user = `cat /tmp/ecp_dbname`
password = `cat /tmp/ecp_dbpass`
query = SELECT email FROM mail_users WHERE email='%s'
EOF

systemctl restart postfix
