#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PWD=$(dirname `dirname $(readlink -f $0)`) || PWD=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

FTP_DB_PASS=`pwgen -1 16`

# Create database
USER_PASS=$(echo "{md5}"`/bin/echo -n "secret" | openssl dgst -binary -md5 | openssl enc -base64`)

#-----------------------------------------------------------------------------------------
# mysql -uroot -e "DROP DATABASE IF EXISTS stackup_ftp"
# mysql -uroot -e "DROP USER IF EXISTS 'stackup_ftp'@'127.0.0.1'"

mysql -uroot -e "CREATE DATABASE IF NOT EXISTS stackup_ftp"
mysql -uroot -e "CREATE USER IF NOT EXISTS 'stackup_ftp'@'127.0.0.1' IDENTIFIED BY '$FTP_DB_PASS'"
mysql -uroot -e "GRANT ALL PRIVILEGES ON stackup_ftp.* TO 'stackup_ftp'@'127.0.0.1'"
mysql -uroot -e "FLUSH PRIVILEGES"

# Install Packages
#-----------------------------------------------------------------------------------------
apt update ; apt -y install pure-ftpd-common pure-ftpd-mysql

mysql -uroot stackup_ftp < $PWD/config/schemas/pureftpd.sql

# Configure Packages
#-----------------------------------------------------------------------------------------
[[ $(cat /etc/group | grep -c webmaster) -eq 1 ]] || groupadd -g 2001 webmaster
[[ $(cat /etc/passwd | grep -c webmaster) -eq 1 ]] || useradd -u 2001 -s /usr/sbin/nologin -d /bin/null -g webmaster webmaster
[[ ! -d /var/www/public_ftp ]] && mkdir -p /var/www/public_ftp
chown -R webmaster:webmaster /var/www/public_ftp
chmod -R 0755 /var/www/public_ftp

rm -fr /etc/pure-ftpd/*
cp -r $PWD/config/pure-ftpd/* /etc/pure-ftpd/.
chown -R root: /etc/pure-ftpd

sed -i "s/HOSTNAME/$(hostname -f)/" /etc/pure-ftpd/pure-ftpd.conf
sed -i "s/DB_HOST/127.0.0.1/"       /etc/pure-ftpd/db-mysql.conf
sed -i "s/DB_PORT/3306/"            /etc/pure-ftpd/db-mysql.conf
sed -i "s/DB_NAME/stackup_ftp/"     /etc/pure-ftpd/db-mysql.conf
sed -i "s/DB_USER/stackup_ftp/"     /etc/pure-ftpd/db-mysql.conf
sed -i "s/DB_PASS/${FTP_DB_PASS}/"  /etc/pure-ftpd/db-mysql.conf

systemctl restart pure-ftpd-mysql
systemctl status pure-ftpd-mysql
# tail -f /var/log/syslog | grep ftpd
