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

rm -fr /etc/pure-ftpd/* && cp -r $PWD/config/pure-ftpd/* /etc/pure-ftpd/.
sed -i "s/DB_HOST/127.0.0.1/"       /etc/pure-ftpd/db-mysql.conf
sed -i "s/DB_PORT/3306/"            /etc/pure-ftpd/db-mysql.conf
sed -i "s/DB_NAME/stackup_ftp/"     /etc/pure-ftpd/db-mysql.conf
sed -i "s/DB_USER/stackup_ftp/"     /etc/pure-ftpd/db-mysql.conf
sed -i "s/DB_PASS/${FTP_DB_PASS}/"  /etc/pure-ftpd/db-mysql.conf

cat > /etc/pure-ftpd/pure-ftpd.conf <<EOF
Umask        133:022
PIDFile      /var/run/pure-ftpd.pid
CertFile     /etc/letsencrypt/live/$(hostname -f)/cert.pem
MinUID       1000
EOF
rm -fr /etc/pure-ftpd/db/ && rm -fr /etc/pure-ftpd/conf/*
echo 'clf:/var/log/pure-ftpd/transfer.log' > /etc/pure-ftpd/conf/AltLog
echo '/etc/pure-ftpd/db-mysql.conf' > /etc/pure-ftpd/conf/MySQLConfigFile
echo '/etc/pure-ftpd/pureftpd.pdb' > /etc/pure-ftpd/conf/PureDB
echo '50000 50100' > /etc/pure-ftpd/conf/PassivePortRange
echo '10000 8' > /etc/pure-ftpd/conf/LimitRecursion
echo '0.0.0.0,21' > /etc/pure-ftpd/conf/Bind
echo 'no' > /etc/pure-ftpd/conf/PAMAuthentication
echo 'no' > /etc/pure-ftpd/conf/AutoRename
echo 'no' > /etc/pure-ftpd/conf/AllowUserFXP
echo 'no' > /etc/pure-ftpd/conf/ProhibitDotFilesWrite
echo 'no' > /etc/pure-ftpd/conf/ProhibitDotFilesRead
echo 'no' > /etc/pure-ftpd/conf/AllowAnonymousFXP
echo 'no' > /etc/pure-ftpd/conf/AnonymousCantUpload
echo 'no' > /etc/pure-ftpd/conf/VerboseLog
echo 'no' > /etc/pure-ftpd/conf/AnonymousCanCreateDirs
echo 'no' > /etc/pure-ftpd/conf/UnixAuthentication
echo 'no' > /etc/pure-ftpd/conf/AnonymousOnly
echo 'no' > /etc/pure-ftpd/conf/BrokenClientsCompatibility
echo 'no' > /etc/pure-ftpd/conf/KeepAllFiles
echo 'yes' > /etc/pure-ftpd/conf/CreateHomeDir
echo 'yes' > /etc/pure-ftpd/conf/ChrootEveryone
echo 'yes' > /etc/pure-ftpd/conf/Daemonize
echo 'yes' > /etc/pure-ftpd/conf/NoChmod
echo 'yes' > /etc/pure-ftpd/conf/DontResolve
echo 'yes' > /etc/pure-ftpd/conf/NoAnonymous
echo 'yes' > /etc/pure-ftpd/conf/DisplayDotFiles
echo 'yes' > /etc/pure-ftpd/conf/IPV4Only
echo 'yes' > /etc/pure-ftpd/conf/AntiWarez
echo 'yes' > /etc/pure-ftpd/conf/CustomerProof
echo 'UTF-8' > /etc/pure-ftpd/conf/FSCharset
echo 'ftp' > /etc/pure-ftpd/conf/SyslogFacility
echo '50' > /etc/pure-ftpd/conf/MaxClientsNumber
echo '10' > /etc/pure-ftpd/conf/MaxClientsPerIP
echo '10' > /etc/pure-ftpd/conf/MaxIdleTime
echo '99' > /etc/pure-ftpd/conf/MaxDiskUsage
echo '4' > /etc/pure-ftpd/conf/MaxLoad
# echo '1' > /etc/pure-ftpd/conf/TLS
# echo 'HIGH:MEDIUM:+TLSv1:!SSLv2:!SSLv3' > /etc/pure-ftpd/conf/TLSCipherSuite
chown -R root: /etc/pure-ftpd
systemctl restart pure-ftpd-mysql
systemctl status pure-ftpd-mysql | grep Active
netstat -pltn | grep ftpd

# tail -f /var/log/syslog | grep ftpd
