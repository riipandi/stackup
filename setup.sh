#!/bin/bash

PWD=$(dirname "$(readlink -f "$0")")

# Check if this script running as root
if [[ $EUID -ne 0 ]]; then
  echo -e 'This script must be run as root' ; exit 1
else
  read -p "Press enter to continue ..."
fi

#-----------------------------------------------------------------------------------------
# 00 - Initial Setup
#-----------------------------------------------------------------------------------------

# Configure Resolver
# echo 'nameserver 209.244.0.3' >  /etc/resolv.conf
# echo 'nameserver 209.244.0.4' >> /etc/resolv.conf

# Upgrade basic system packages
source $PWD/installer/repositories.sh
apt update ; apt -y full-upgrade
apt -y autoremove

#-----------------------------------------------------------------------------------------
# 01 - Installing Packages
#-----------------------------------------------------------------------------------------
apt -y install sudo nano figlet elinks pwgen curl crudini lsof ntp ntpdate perl dirmngr \
software-properties-common debconf-utils apt-transport-https

curl -L# https://semut.org/gdrive -o /usr/bin/gdrive ; chmod a+x /usr/bin/gdrive

#-----------------------------------------------------------------------------------------
# 02 - Ask the questions
#-----------------------------------------------------------------------------------------

read -e -p "Please specify SSH port  : " -i "22" ssh_port
cat $ssh_port > /tmp/ssh_port

read -e -p "Disable IPv6       (y/n) : " -i "y" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then echo Yes > /tmp/disable_ipv6 ;fi

read -e -p "Install PostgreSQL   y/n : " -i "n" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then echo Yes > /tmp/install_pgsql ;fi

read -e -p "Install Redis Server y/n : " -i "n" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then echo Yes > /tmp/install_redis ;fi

read -e -p "Install FTP Server   y/n : " -i "n" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then echo Yes > /tmp/install_ftpd ;fi

read -e -p "Install DNS Server   y/n : " -i "n" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then echo Yes > /tmp/install_pdns ;fi

read -e -p "Install IMAP Sync    y/n : " -i "n" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then echo Yes > /tmp/install_imaps ;fi

read -e -p "Database Bind Address    : " -i "127.0.0.1" db_bindaddr
if [ "$db_bindaddr" != "" ] ;then
  echo "$db_bindaddr" > /tmp/db_bindaddr
else
  echo "127.0.0.1" > /tmp/db_bindaddr
fi

#-----------------------------------------------------------------------------------------
# 03 - Basic Configuration
#-----------------------------------------------------------------------------------------

# Server Timezone
read -e -p "Please specify time zone : " -i "Asia/Jakarta" timezone
if [ "`cat /tmp/country`" != "ID" ] || [ "`cat /tmp/country`" != "SG" ] ; then
  ntpdate -u pool.ntp.org
else
  ntpdate -u 0.asia.pool.ntp.org
fi
timedatectl set-timezone $timezone

# SSH Server
figlet `hostname -f` > /etc/motd
perl -pi -e 's#(.*sudo.*ALL=)(.*)#${1}(ALL) NOPASSWD:ALL#' /etc/sudoers
sed -i "s|\("^PubkeyAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ClientAliveInterval" * *\).*|\1600|" /etc/ssh/sshd_config
sed -i "s|\("^AllowTcpForwarding" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ClientAliveCountMax" * *\).*|\13|" /etc/ssh/sshd_config
sed -i "s|\("^ListenAddress" * *\).*|\10.0.0.0|" /etc/ssh/sshd_config
sed -i "s|\("^PermitRootLogin" * *\).*|\1no|" /etc/ssh/sshd_config
sed -i "s|\("^PermitTunnel" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^StrictModes" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s/[#]*ListenAddress/ListenAddress/" /etc/ssh/sshd_config
sed -i "s/[#]*Port [0-9]*/Port $(cat /tmp/ssh_port)/" /etc/ssh/sshd_config
sed -i "s/ListenAddress :://" /etc/ssh/sshd_config
systemctl restart ssh

# Sysctl configuration
crudini --set /etc/sysctl.conf '' 'net.ipv4.ip_forward'   '1'
crudini --set /etc/sysctl.conf '' 'vm.vfs_cache_pressure' '50'
crudini --set /etc/sysctl.conf '' 'vm.swappiness'         '10'
sysctl -p

# Disable IPv6
if [ "`cat /tmp/disable_ipv6`" == "Yes" ] ;then
  sed -i "s/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/" /etc/gai.conf
  crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.all.disable_ipv6'     '1'
  crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.default.disable_ipv6' '1'
  crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.lo.disable_ipv6'      '1'
  echo -e 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
  sysctl -p
fi

#-----------------------------------------------------------------------------------------
# 04 - Configure Telegram Notification
#-----------------------------------------------------------------------------------------
read -e -p "Telegram notify    (y/n) : " -i "n" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
  read -e -p "Telegram Chat ID         : " -i "" tg_userid
  read -e -p "Telegram Bot Key         : " -i "" tg_userid
  cp $PWD/scripts/sshnotify.sh /etc/profile.d/
  echo "USERID='$tg_userid'" > /etc/sshnotify.conf
  echo "BOTKEY='$tg_botkey'" >> /etc/sshnotify.conf
  chmod a+x /etc/profile.d/sshnotify.sh
fi

#-----------------------------------------------------------------------------------------
# 05 - Begin installation process
#-----------------------------------------------------------------------------------------
read -e -p "Install Amplify    (y/n) : " -i "n" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
  echo Yes > /tmp/install_amplify
  read -e -p "Nginx Amplify Key        : " -i "" amplify_key
  if [ "$amplify_key" != "" ] ;then
    echo $amplify_key > /tmp/amplify_key
  fi
fi

# Database name and password for eCP
echo "ecp_`pwgen -1 -A 8`" > /tmp/ecp_dbname
echo `pwgen -1 12` > /tmp/ecp_dbpass

source $PWD/installer/webserver.sh

#-----------------------------------------------------------------------------------------
# 06 - Additional components
#-----------------------------------------------------------------------------------------

[[ "`cat /tmp/install_pgsql`" != "Yes" ]] || source $PWD/installer/postgresql.sh

[[ "`cat /tmp/install_redis`" != "Yes" ]] || source $PWD/installer/rediscache.sh

[[ "`cat /tmp/install_ftpd`" != "Yes" ]] || source $PWD/installer/ftpserver.sh

[[ "`cat /tmp/install_pdns`" != "Yes" ]] || source $PWD/installer/powerdns.sh

[[ "`cat /tmp/install_imaps`" != "Yes" ]] || source $PWD/installer/imapsync.sh


#-----------------------------------------------------------------------------------------
# 07 - Cleanup
#-----------------------------------------------------------------------------------------
apt -y autoremove

echo -e "\n" && netstat -pltn && echo -e "\n"

echo -e "Server stack has been installed."
echo -e "Control Panel DB: `cat /tmp/ecp_dbname`"
echo -e "DB Root Password: `cat /tmp/ecp_dbpass`"
echo -e "\n"

read -e -p "Reboot the server    y/n : " -i "y" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then shutdown -r now ; fi
