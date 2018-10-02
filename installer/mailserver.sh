#!/bin/bash

PWD=$(dirname "$(readlink -f "$0")")
PARENT=$(dirname $PWD)

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

apt -y install postfix postfix-mysql
systemctl enable --now postfix

postconf virtual_mailbox_domains=mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
postconf virtual_mailbox_maps=mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
postconf virtual_alias_domains=mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
postconf virtual_alias_maps=mysql:/etc/postfix/mysql-virtual-alias-maps.cf,mysql:/etc/postfix/mysql-email2email.cf

systemctl restart postfix
netstat -tulpn | grep 25
postconf -n | grep virtual

cat > /etc/postfix/mysql-virtual-mailbox-domains.cf <<EOF
hosts = 127.0.0.1
dbname = elsacp
user = elsacp
password = che0oGaeh8shaeh5
query = SELECT 1 FROM domains WHERE name='%s'
EOF

cat > /etc/postfix/mysql-virtual-mailbox-maps.cf <<EOF
hosts = 127.0.0.1
dbname = elsacp
user = elsacp
password = che0oGaeh8shaeh5
query = SELECT 1 FROM mail_users WHERE email='%s'
EOF

cat > /etc/postfix/mysql-virtual-alias-maps.cf <<EOF
hosts = 127.0.0.1
dbname = elsacp
user = elsacp
password = che0oGaeh8shaeh5
query = SELECT destination FROM mail_aliases WHERE source='%s'
EOF

cat > /etc/postfix/mysql-email2email.cf <<EOF
hosts = 127.0.0.1
dbname = elsacp
user = elsacp
password = che0oGaeh8shaeh5
query = SELECT email FROM mail_users WHERE email='%s'
EOF

# Insert some records
cat > /tmp/postfix.sql <<EOF
INSERT INTO domains (id, name, master, last_check, type, notified_serial, account) VALUES
 (NULL, 'aris.web.id', NULL, NULL, 'NATIVE', NULL, NULL),
 (NULL, 'ripandi.id', NULL, NULL, 'NATIVE', NULL, NULL);

INSERT INTO mail_users (id, domain_id, password , email) VALUES
 ('1', '10', ENCRYPT('password', CONCAT('$6$', SUBSTRING(SHA(RAND()), -16))), 'contact@aris.web.id'),
 ('2', '11', ENCRYPT('password', CONCAT('$6$', SUBSTRING(SHA(RAND()), -16))), 'aris@ripandi.id');

TRUNCATE TABLE mail_aliases;
INSERT INTO mail_aliases () VALUES
 ('1', '11', 'aris@ripandi.id', 'ar.is@outlook.com'),
 ('2', '10', 'contact@aris.web.id', 'riipandi@gmail.com');
EOF

# Check the records
postmap -q ripandi.id mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
postmap -q aris@ripandi.id mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
postmap -q aris@ripandi.id mysql:/etc/postfix/mysql-virtual-alias-maps.cf
postmap -q contact@aris.web.id mysql:/etc/postfix/mysql-virtual-alias-maps.cf
postmap -q admin@aris.web.id mysql:/etc/postfix/mysql-email2email.cf
