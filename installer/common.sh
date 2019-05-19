#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PWD=$(dirname `dirname $(readlink -f $0)`) || PWD=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

# Disable some motd banner
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Disabling Ubuntu motd message...${NC}"
chmod -x /etc/update-motd.d/*
chmod +x /etc/update-motd.d/00-header
chmod +x /etc/update-motd.d/97-overlayroot
chmod +x /etc/update-motd.d/98-fsck-at-reboot
chmod +x /etc/update-motd.d/98-reboot-required
chmod +x /etc/update-motd.d/50-landscape-sysinfo

# Change default repository
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Upgrading system...${NC}"
COUNTRY=$(wget -qO- ipapi.co/json | grep '"country":' | sed -E 's/.*"([^"]+)".*/\1/')
if   [ $COUNTRY == "ID" ] ; then cat $PWD/config/repo/sources-id.list > /etc/apt/sources.list
elif [ $COUNTRY == "SG" ] ; then cat $PWD/config/repo/sources-sg.list > /etc/apt/sources.list
elif [ $COUNTRY == "US" ] ; then cat $PWD/config/repo/sources-us.list > /etc/apt/sources.list
else cat $PWD/config/repo/sources.list > /etc/apt/sources.list ; fi
sed -i "s/CODENAME/$(lsb_release -cs)/" /etc/apt/sources.list
apt update -qq ; apt -y full-upgrade ; apt -y autoremove

# Install basic packages
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Installing basic packages...${NC}"
apt -y install sudo nano figlet elinks pwgen curl lsof whois dirmngr gnupg gcc make \
cmake build-essential software-properties-common debconf-utils apt-transport-https \
perl binutils dnsutils nscd ftp zip unzip bsdtar pv dh-autoreconf rsync screenfetch \
screen ca-certificates nmap nikto xmlstarlet speedtest-cli optipng jpegoptim sqlite3 \
s3cmd virtualenv libpython2.7 {libpython,libpython2.7,python2.7}-dev gunicorn gunicorn3 \
python3-venv {python,python3}-{click,dev,pip,setuptools,gunicorn,virtualenv} \
python-{m2crypto,configparser,pip-whl} supervisor

# SSH Server + welcome message
#-----------------------------------------------------------------------------------------
if [ -f "$PWD/stackup.ini" ]; then
    [[ $(cat "$PWD/stackup.ini" | grep -c "ssh_port") -eq 1 ]] && ssh_port=$(crudini --get $PWD/stackup.ini '' 'ssh_port')
    [[ -z "$ssh_port" ]] && read -ep "Please specify SSH port                         : " -i "22" ssh_port
fi

perl -pi -e 's#(.*sudo.*ALL=)(.*)#${1}(ALL) NOPASSWD:ALL#' /etc/sudoers
sed -i "s/#ListenAddress :://" /etc/ssh/sshd_config
sed -i "s/[#]*PasswordAuthentication/PasswordAuthentication/" /etc/ssh/sshd_config
sed -i "s/[#]*PubkeyAuthentication/PubkeyAuthentication/" /etc/ssh/sshd_config
sed -i "s/[#]*ClientAliveInterval/ClientAliveInterval/" /etc/ssh/sshd_config
sed -i "s/[#]*AllowTcpForwarding/AllowTcpForwarding/" /etc/ssh/sshd_config
sed -i "s/[#]*ClientAliveCountMax/ClientAliveCountMax/" /etc/ssh/sshd_config
sed -i "s/[#]*PermitRootLogin/PermitRootLogin/" /etc/ssh/sshd_config
sed -i "s/[#]*ListenAddress/ListenAddress/" /etc/ssh/sshd_config
sed -i "s/[#]*PermitTunnel/PermitTunnel/" /etc/ssh/sshd_config
sed -i "s/[#]*X11Forwarding/X11Forwarding/" /etc/ssh/sshd_config
sed -i "s/[#]*StrictModes/StrictModes/" /etc/ssh/sshd_config
sed -i "s|\("^PasswordAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^PubkeyAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ClientAliveInterval" * *\).*|\1600|" /etc/ssh/sshd_config
sed -i "s|\("^AllowTcpForwarding" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ClientAliveCountMax" * *\).*|\13|" /etc/ssh/sshd_config
sed -i "s|\("^ListenAddress" * *\).*|\10.0.0.0|" /etc/ssh/sshd_config
sed -i "s|\("^PermitRootLogin" * *\).*|\1no|" /etc/ssh/sshd_config
sed -i "s|\("^PermitTunnel" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^X11Forwarding" * *\).*|\1no|" /etc/ssh/sshd_config
sed -i "s|\("^StrictModes" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s/[#]*Port [0-9]*/Port $ssh_port/" /etc/ssh/sshd_config
echo -e "$(figlet node://`hostname -s`)\n" > /etc/motd
systemctl restart ssh

# Sysctl tweak
crudini --set /etc/sysctl.conf '' 'net.ipv4.ip_forward'   '1'
crudini --set /etc/sysctl.conf '' 'vm.vfs_cache_pressure' '50'
crudini --set /etc/sysctl.conf '' 'vm.swappiness'         '10'
sysctl -p -q >/dev/null 2>&1

# Linux SWAP
#-----------------------------------------------------------------------------------------
swap_install=$(crudini --get $WORKDIR/stackup.ini '' 'swap_install')
if [[ "${swap_install,,}" =~ ^(yes|y)$ ]] ; then
    if [ -f "$PWD/stackup.ini" ]; then
        [[ $(cat "$PWD/stackup.ini" | grep -c "swap_size") -eq 1 ]] && swap_size=$(crudini --get $PWD/stackup.ini '' 'swap_size')
        [[ -z "$swap_size" ]] && read -ep "Enter size of Swap (in megabyte)                : " -i "2048" swap_size
    fi
    if [[ $(cat /etc/fstab | grep -c "swapfile") -eq 0 ]]; then
        echo -e "\n${OK}Configuring Linux SWAP...${NC}"
        echo "/swapfile  none  swap  sw  0 0" >> /etc/fstab
        dd if=/dev/zero of=/swapfile count=$swap_size bs=1M
        chmod 600 /swapfile && mkswap /swapfile
        swapon /swapfile && swapon --show
    else
        echo -e "\n${OK}Swapfile already configured...${NC}"
    fi
fi

# Timezone
#-----------------------------------------------------------------------------------------
if [ -f "$PWD/stackup.ini" ]; then
    [[ $(cat "$PWD/stackup.ini" | grep -c "timezone") -eq 1 ]] && timezone=$(crudini --get $PWD/stackup.ini '' 'timezone')
    [[ -z "$timezone" ]] && read -ep "Please specify time zone                        : " -i "Asia/Jakarta" timezone
fi
[[ $(which ntp) -ne 0 ]] && apt purge -yqq ntp ntpdate
timedatectl set-ntp true
timedatectl set-timezone $timezone
systemctl enable systemd-timesyncd
systemctl restart systemd-timesyncd

# Disable IPv6
#-----------------------------------------------------------------------------------------
if [ -f "$PWD/stackup.ini" ]; then
    [[ $(cat "$PWD/stackup.ini" | grep -c "disable_ipv6") -eq 1 ]] && disable_ipv6=$(crudini --get $PWD/stackup.ini '' 'disable_ipv6')
    if [[ "${disable_ipv6,,}" =~ ^(yes|y)$ ]] ; then
        echo -e "\n${OK}Disabling IPv6...${NC}"
        sed -i "s/ListenAddress :://" /etc/ssh/sshd_config
        sed -i "s/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/" /etc/gai.conf
        crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.all.disable_ipv6'     '1'
        crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.default.disable_ipv6' '1'
        crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.lo.disable_ipv6'      '1'
        echo -e 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
        sysctl -p -q
    fi
fi
