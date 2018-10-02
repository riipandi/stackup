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
echo 'nameserver 209.244.0.3' >  /etc/resolv.conf
echo 'nameserver 209.244.0.4' >> /etc/resolv.conf

# Upgrade basic system packages
source $PWD/installer/repositories.sh
apt update ; apt -y full-upgrade

#-----------------------------------------------------------------------------------------
# 01 - Installing Packages
#-----------------------------------------------------------------------------------------
apt -y install figlet elinks pwgen curl crudini lsof ntp perl
curl -L# https://semut.org/gdrive -o /usr/bin/gdrive
chmod a+x /usr/bin/gdrive

#-----------------------------------------------------------------------------------------
# 02 - Basic Configuration
#-----------------------------------------------------------------------------------------
perl -pi -e 's#(.*sudo.*ALL=)(.*)#${1}(ALL) NOPASSWD:ALL#' /etc/sudoers

# Server Timezone
echo -n "Please specify time zone (Asia/Jakarta) : " ; read timezone
if [ "$timezone" != "" ] ;then
  timedatectl set-timezone $timezone
  ntpdate -u pool.ntp.org
else
  timedatectl set-timezone Asia/Jakarta
  ntpdate -u 0.asia.pool.ntp.org
fi

# Sysctl configuration
crudini --set /etc/sysctl.conf '' 'net.ipv4.ip_forward'   '1'
crudini --set /etc/sysctl.conf '' 'vm.vfs_cache_pressure' '50'
crudini --set /etc/sysctl.conf '' 'vm.swappiness'         '10'

# Disable IPv6 + Swapfile
echo -n "Do you want to disable IPv6 (y/n) ? " ; read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
  crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.all.disable_ipv6'     '1'
  crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.default.disable_ipv6' '1'
  crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.lo.disable_ipv6'      '1'
fi

# SSH Server
figlet `hostname -f` > /etc/motd
sed -i "s|\("^PubkeyAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ClientAliveInterval" * *\).*|\1600|" /etc/ssh/sshd_config
sed -i "s|\("^AllowTcpForwarding" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ClientAliveCountMax" * *\).*|\13|" /etc/ssh/sshd_config
sed -i "s|\("^ListenAddress" * *\).*|\10.0.0.0|" /etc/ssh/sshd_config
sed -i "s|\("^PermitRootLogin" * *\).*|\1no|" /etc/ssh/sshd_config
sed -i "s|\("^PermitTunnel" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^StrictModes" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s/[#]*ListenAddress/ListenAddress/" /etc/ssh/sshd_config
sed -i "s/ListenAddress :://" /etc/ssh/sshd_config

echo -n "Please specify SSH server port number (default 22) : " ; read ssh_port
if [ "$ssh_port" != "" ] ;then
  sed -i "s/[#]*Port [0-9]*/Port $ssh_port/" /etc/ssh/sshd_config
else
  sed -i "s/[#]*Port [0-9]*/Port 22/" /etc/ssh/sshd_config
fi
systemctl restart ssh

#-----------------------------------------------------------------------------------------
# 03 - Configure Telegram Notification
#-----------------------------------------------------------------------------------------
echo -n "Do you want to enable Telegram notification (y/n) ? " ; read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
  echo -n "Telegram Chat ID : " ; read tg_userid
  echo -n "Telegram Bot Key : " ; read tg_botkey
  cp $PWD/scripts/sshnotify.sh /etc/profile.d/
  echo "USERID='$tg_userid'" > /etc/sshnotify.conf
  echo "BOTKEY='$tg_botkey'" >> /etc/sshnotify.conf
  chmod a+x /etc/profile.d/sshnotify.sh
fi

#-----------------------------------------------------------------------------------------
# 04 - Begin installation process
#-----------------------------------------------------------------------------------------
echo -e "" ; read -p "Press enter to continue" ; echo -e "\n"

echo -n "Database Server Bind Address (127.0.0.1) : " ; read db_bindaddr
if [ "$db_bindaddr" != "" ] ;then
  echo "$db_bindaddr" > /tmp/db_bindaddr
else
  echo "127.0.0.1" > /tmp/db_bindaddr
fi

# Database name and password for eCP
echo "ecp_`pwgen -1 -A 8`" > /tmp/ecp_dbname
echo `pwgen -1 12` > /tmp/ecp_dbpass

echo -n "Do you want to install Nginx Amplify (y/n) ? " ; read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
  echo Yes > /tmp/install_amplify
  echo -n "Nginx Amplify API Key : " ; read amplify_key
  if [ "$amplify_key" != "" ] ;then
    echo $amplify_key > /tmp/amplify_key
  fi
fi

source $PWD/installer/webserver.sh

#-----------------------------------------------------------------------------------------
# 05 - Additional components
#-----------------------------------------------------------------------------------------

echo -n "Do you want to install PostgreSQL (y/n) ? " ; read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
  source $PWD/installer/postgresql.sh
fi

echo -n "Do you want to install Redis Server (y/n) ? " ; read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
  source $PWD/installer/rediscache.sh
fi

echo -n "Do you want to install FTP Server (y/n) ? " ; read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
  source $PWD/installer/ftpserver.sh
fi

echo -n "Do you want to install DNS Server (y/n) ? " ; read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
  source $PWD/installer/powerdns.sh
fi

echo -n "Do you want to install IMAPSync (y/n) ? " ; read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
  source $PWD/installer/imapsync.sh
fi

#-----------------------------------------------------------------------------------------
# 06 - Cleanup
#-----------------------------------------------------------------------------------------
apt -y autoremove

echo -e "\n" && netstat -pltn && echo -e "\n"

echo -e "Server stack has been installed."
echo -e "Control Panel DB: `cat /tmp/ecp_dbname`"
echo -e "DB Root Password: `cat /tmp/ecp_dbpass`"
echo -e "\n"

echo -n "Do you want to reboot (y/n) ? " ; read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then shutdown -r now ; fi
