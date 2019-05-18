#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PWD=$(dirname `dirname $(readlink -f $0)`) || PWD=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

# Configure the system
#-----------------------------------------------------------------------------------------
read -ep "Please specify time zone                        : " -i "Asia/Jakarta" timezone

# Timezone Synchronization
if [[ $(which ntp) -ne 0 ]]; then apt purge -yqq ntp ntpdate ; fi

timedatectl set-ntp true
timedatectl set-timezone $timezone
systemctl enable systemd-timesyncd
systemctl restart systemd-timesyncd

# Sysctl tweak
crudini --set /etc/sysctl.conf '' 'net.ipv4.ip_forward'   '1'
crudini --set /etc/sysctl.conf '' 'vm.vfs_cache_pressure' '50'
crudini --set /etc/sysctl.conf '' 'vm.swappiness'         '10'
sysctl -p -q >/dev/null 2>&1

# Disable IPv6
read -ep "Do you want to disable IPv6?                y/n : " -i "n" answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    echo -e "\n${OK}Disabling IPv6...${NC}"
    sed -i "s/ListenAddress :://" /etc/ssh/sshd_config
    sed -i "s/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/" /etc/gai.conf
    crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.all.disable_ipv6'     '1'
    crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.default.disable_ipv6' '1'
    crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.lo.disable_ipv6'      '1'
    echo -e 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
    sysctl -p -q
fi
