#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PARENT=$(dirname `dirname $(readlink -f $0)`) || PARENT=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

# Disable some motd banner
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Disabling Ubuntu motd message...${NC}"
chmod -x /etc/update-motd.d/10-help-text
chmod -x /etc/update-motd.d/50-motd-news
chmod -x /etc/update-motd.d/80-livepatch
chmod -x /etc/update-motd.d/90-updates-available

# Disable sudo password
#-----------------------------------------------------------------------------------------
perl -pi -e 's#(.*sudo.*ALL=)(.*)#${1}(ALL) NOPASSWD:ALL#' /etc/sudoers

# Change default repository
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Upgrading system...${NC}"
COUNTRY=$(wget -qO- ipapi.co/json | grep '"country":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ $COUNTRY == "ID" ] ; then
    cat $PARENT/config/repo/sources-id.list > /etc/apt/sources.list
elif [ $COUNTRY == "SG" ] ; then
    cat $PARENT/config/repo/sources-sg.list > /etc/apt/sources.list
else
    cat $PARENT/config/repo/sources.list > /etc/apt/sources.list
fi
sed -i "s/CODENAME/$(lsb_release -cs)/" /etc/apt/sources.list
apt update ; apt -y full-upgrade ; apt -y autoremove

# Install basic packages
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Installing basic packages...${NC}"
apt -y install sudo nano figlet elinks pwgen curl lsof whois dirmngr gnupg \
gcc make cmake build-essential software-properties-common debconf-utils \
apt-transport-https perl binutils dnsutils nscd ftp zip unzip bsdtar pv \
dh-autoreconf rsync screen screenfetch ca-certificates nmap nikto xmlstarlet \
speedtest-cli optipng jpegoptim sqlite3 s3cmd virtualenv libpython2.7 \
{libpython,libpython2.7,python2.7}-dev python-virtualenv python3-virtualenv \
python3-venv python-click
