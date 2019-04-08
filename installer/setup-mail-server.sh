#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PARENT=$(dirname `dirname $(readlink -f $0)`) || PARENT=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

ROOT_DOMAIN_NAME="example.com"
MAIL_DB_PASSWORD=`pwgen -1 16`

# Create database
#-----------------------------------------------------------------------------------------
mysql -e "CREATE DATABASE IF NOT EXISTS stackup_mail"
mysql -e "CREATE USER IF NOT EXISTS 'stackup_mail'@'127.0.0.1' IDENTIFIED BY '$MAIL_DB_PASSWORD'"
mysql -e "GRANT ALL PRIVILEGES ON stackup_mail.* TO 'stackup_mail'@'127.0.0.1'"
mysql -e "FLUSH PRIVILEGES"

# Generate SSL Certificate
#-----------------------------------------------------------------------------------------
systemctl stop nginx
certbot certonly --standalone --rsa-key-size 4096 --agree-tos --register-unsafely-without-email \
 -d mail.${ROOT_DOMAIN_NAME} -d smtp.${ROOT_DOMAIN_NAME} -d imap.${ROOT_DOMAIN_NAME}
systemctl restart nginx

# Install packages
#-----------------------------------------------------------------------------------------
debconf-set-selections <<< "postfix postfix/mailname string mail.${ROOT_DOMAIN_NAME}"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt -y install postfix postfix-policyd-spf-python postfix-pcre postfix-mysql opendkim opendkim-tools \
dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql mailutils spamassassin spamc

# Configure SPF and DMARC
# SPF:   v=spf1 include:mail.example.com ~all
# DMARC: v=DMARC1;p=quarantine;sp=quarantine;adkim=r;aspf=r
#-----------------------------------------------------------------------------------------
adduser postfix opendkim
mkdir -p /etc/opendkim/keys /var/run/opendkim /var/spool/postfix/opendkim
crudini --set /etc/default/opendkim '' 'SOCKET' 'local:/var/spool/postfix/opendkim/opendkim.sock'

chown -R opendkim:postfix /var/spool/postfix/opendkim
chown -R opendkim:opendkim /etc/opendkim
chmod u=rw,go=r /etc/opendkim.conf
chmod -R go-rw /etc/opendkim

touch /etc/opendkim/trusted.hosts
cat > /etc/opendkim/trusted.hosts <<EOF
127.0.0.1
::1
localhost
$(hostname -s)
$(hostname -f)
${ROOT_DOMAIN_NAME}
EOF

cd /etc/opendkim/keys
echo '*@example.com  example' > /etc/opendkim/signing.table
echo "example example.com:$(date +%Y%m):/etc/opendkim/keys/example.private" > /etc/opendkim/key.table
opendkim-genkey -b 2048 -h rsa-sha256 -r -s $(date +%Y%m) -d example.com -v
mv $(date +%Y%m).private example.private
mv $(date +%Y%m).txt example.txt
chmod go-rw /etc/opendkim/keys/*

systemctl restart opendkim
systemctl status -l opendkim

#cat /etc/opendkim/example.txt
#v=DKIM1; h=sha256; k=rsa; s=email; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2j54tLYxkiXxCQJE5NTVX3qYIANau8QpPIWYvhUgkl1k4QLxzRJdDxmYZlJB8u2orJzcJNCoHlwMoJbyTnxETdPDllVYul+4GAbi6JCus/KrToPijZtFpdn+mJLU7piQgHDmJXTqWAXTxkUmlbJtvJeOMriMf5QXHF4J9ae+viQYNfXHwSQ6WF85wxEpf8eZjchKW/2IjofeIksg6PBvCY5vpiHVS65mdPSDMElA6VyMLm2Idtph+EqKnko6h6yQ9wj4HW8/YCLVQEluq3E1diPMP1Do6dhlIz4xaf/1rPvNrYvXe+z4xtXk9l59uKL9shTt2jnViIddPqvymqEP9wIDAQAB
#opendkim-testkey -d example.com -s $(date +%Y%m)

# Configure Postfix
#-----------------------------------------------------------------------------------------
sed -i "s/MAIL_HOSTNAME/mail.${ROOT_DOMAIN_NAME}/" /etc/postfix/main.cf
sed -i "s/secret/${MAIL_DB_PASSWORD}/" /etc/postfix/mysql-virtual-alias-maps.cf
sed -i "s/secret/${MAIL_DB_PASSWORD}/" /etc/postfix/mysql-virtual-email2email.cf
sed -i "s/secret/${MAIL_DB_PASSWORD}/" /etc/postfix/mysql-virtual-mailbox-domains.cf
sed -i "s/secret/${MAIL_DB_PASSWORD}/" /etc/postfix/mysql-virtual-mailbox-maps.cf
chmod -R o-rwx /etc/postfix ; systemctl restart postfix ; systemctl status -l postfix

# Configure Dovecot
#-----------------------------------------------------------------------------------------
groupadd -g 5000 vmail ; useradd -g vmail -u 5000 vmail -d /var/mail
sed -i "s/example.com/${ROOT_DOMAIN_NAME}/" /etc/dovecot/dovecot.conf
sed -i "s/secret/${MAIL_DB_PASSWORD}/" /etc/dovecot/dovecot-sql.conf.ext
sed -i "s/MAIL_HOSTNAME/mail.${ROOT_DOMAIN_NAME}/" /etc/dovecot/conf.d/10-ssl.conf
chown -R vmail:dovecot /etc/dovecot ; chmod -R o-rwx /etc/dovecot

mkdir -p /var/mail/vhosts/${ROOT_DOMAIN_NAME}
chown -R vmail:vmail /var/mail
chmod -R 0777 /var/mail/vhosts

systemctl restart dovecot
systemctl status -l dovecot

# SpamAssassin
#-----------------------------------------------------------------------------------------
cat > /etc/default/spamassassin <<EOF
ENABLED=1
OPTIONS="--create-prefs --max-children 5 --username spamd --helper-home-dir /home/spamd/ -s /home/spamd/spamd.log"
PIDFILE="/var/run/spamd.pid"
#NICE="--nicelevel 15"
CRON=1
SAHOME="/var/log/spamassassin/"
EOF
cat > /etc/spamassassin/local.cf <<EOF
rewrite_header Subject [***** SPAM _SCORE_ *****]
required_score 5.0
use_bayes 1
bayes_auto_learn 1
ifplugin Mail::SpamAssassin::Plugin::Shortcircuit
endif # Mail::SpamAssassin::Plugin::Shortcircuit
EOF
service spamassassin restart
systemctl status -l spamassassin

tail -f /var/log/syslog
