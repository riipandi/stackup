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
    [[ $(cat "$PWD/stackup.ini" | grep -c "ssh_port") -eq 1 ]] && ssh_port=$(crudini --get $PWD/stackup.ini 'setup' 'ssh_port')
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
