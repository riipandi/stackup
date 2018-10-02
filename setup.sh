#!/bin/bash

PWD=$(dirname "$(readlink -f "$0")")

# Check if this script running as root
if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

#-----------------------------------------------------------------------------------------
# Check configuration file
#-----------------------------------------------------------------------------------------
if [ ! -f $PWD/envar ]; then

cat > $PWD/envar <<EOF
SSH_PORT="22"
TIMEZONE="Asia/Jakarta"

DB_ROOT_PASS="xxxxxxxxx"
DB_BIND_ADDR="127.0.0.1"

NGX_AMPLIFY_KEY="xxxxxxx"
TELEGRAM_USERID="xxxxxxx"
TELEGRAM_BOTKEY="xxxxxxx"
EOF

    echo -e "Please edit envar file then run this script again!"
    exit 1
fi

echo -e "" ; read -p "Press enter to continue" ; echo -e "\n"

source $PWD/envar

#-----------------------------------------------------------------------------------------
# 00 - Initial Setup
#-----------------------------------------------------------------------------------------

# Configure Resolver
echo 'nameserver 209.244.0.3' >  /etc/resolv.conf
echo 'nameserver 209.244.0.4' >> /etc/resolv.conf

# Database name and password for eCP
echo "ecp_`pwgen -1 -A 8`" > /tmp/ecp_dbname
echo `pwgen -1 12` > /tmp/ecp_dbpass

# Upgrade basic system packages
source $PWD/installer/repositories.sh
apt update ; apt -y full-upgrade
apt -y autoremove

#-----------------------------------------------------------------------------------------
# 01 - Installing Packages
#-----------------------------------------------------------------------------------------
apt -y install figlet elinks pwgen curl crudini lsof ntp

# Google Drive Client
curl -L# https://semut.org/gdrive -o /usr/bin/gdrive
chmod a+x /usr/bin/gdrive

#-----------------------------------------------------------------------------------------
# 02 - Basic Configuration
#-----------------------------------------------------------------------------------------
perl -pi -e 's#(.*sudo.*ALL=)(.*)#${1}(ALL) NOPASSWD:ALL#' /etc/sudoers
timedatectl set-timezone $TIMEZONE
ntpdate -u 0.asia.pool.ntp.org

# Disable IPv6 + Swapfile
crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.all.disable_ipv6'     '1'
crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.default.disable_ipv6' '1'
crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.lo.disable_ipv6'      '1'
crudini --set /etc/sysctl.conf '' 'net.ipv4.ip_forward'   '1'
crudini --set /etc/sysctl.conf '' 'vm.vfs_cache_pressure' '50'
crudini --set /etc/sysctl.conf '' 'vm.swappiness' '10'

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
sed -i "s/[#]*Port [0-9]*/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i "s/ListenAddress :://" /etc/ssh/sshd_config
systemctl restart ssh

#-----------------------------------------------------------------------------------------
# 03 - Configure Telegram Notification
#-----------------------------------------------------------------------------------------
cp $PWD/scripts/sshnotify.sh /etc/profile.d/
chmod a+x /etc/profile.d/sshnotify.sh
cat > /etc/sshnotify.conf <<EOF
USERID='$TELEGRAM_USERID'
BOTKEY='$TELEGRAM_BOTKEY'
EOF
