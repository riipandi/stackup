#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PARENT=$(dirname `dirname $(readlink -f $0)`) || PARENT=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

read -ep "Please specify SSH port                         : " -i "22" ssh_port

# SSH Server + welcome message
#-----------------------------------------------------------------------------------------
sed -i "s/#ListenAddress :://" /etc/ssh/sshd_config
sed -i "s/[#]*PubkeyAuthentication/PubkeyAuthentication/" /etc/ssh/sshd_config
sed -i "s/[#]*ClientAliveInterval/ClientAliveInterval/" /etc/ssh/sshd_config
sed -i "s/[#]*AllowTcpForwarding/AllowTcpForwarding/" /etc/ssh/sshd_config
sed -i "s/[#]*ClientAliveCountMax/ClientAliveCountMax/" /etc/ssh/sshd_config
sed -i "s/[#]*PermitRootLogin/PermitRootLogin/" /etc/ssh/sshd_config
sed -i "s/[#]*ListenAddress/ListenAddress/" /etc/ssh/sshd_config
sed -i "s/[#]*PermitTunnel/PermitTunnel/" /etc/ssh/sshd_config
sed -i "s/[#]*X11Forwarding/X11Forwarding/" /etc/ssh/sshd_config
sed -i "s/[#]*StrictModes/StrictModes/" /etc/ssh/sshd_config
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
systemctl restart ssh

# Set custom motd message
#-----------------------------------------------------------------------------------------
echo -e "$(figlet node://`hostname -s`)\n" > /etc/motd
