#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
NOCOLOR='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;33m'
BLUE='\033[0;34m'
CURRENT=$(dirname $(readlink -f $0))
[ -z $ROOTDIR ] && PWD=$(dirname `dirname $CURRENT`) || PWD=$ROOTDIR

# Determine os version codename
osver=`echo $(lsb_release -c | cut -d':' -f 2) | tr '[:upper:]' '[:lower:]'`

#----------------------------------------------------------------------------------
# --
#----------------------------------------------------------------------------------

# Change default repository mirror
#-----------------------------------------------------------------------------------------
echo -e "\n${BLUE}Upgrading system...${NOCOLOR}"
# COUNTRY=$(wget -qO- ipapi.co/json | grep '"country":' | sed -E 's/.*"([^"]+)".*/\1/')
# if   [ $COUNTRY == "ID" ] ; then REPOFILE="$PWD/config/repo/debian-id.list"
# elif [ $COUNTRY == "SG" ] ; then REPOFILE="$PWD/config/repo/debian-id.list"
# elif [ $COUNTRY == "US" ] ; then REPOFILE="$PWD/config/repo/debian-id.list"
# else REPOFILE="$PWD/config/repo/debian.list" ; fi
REPOFILE="$PWD/config/repo/debian.list"

cat "$PWD/config/repo/debian.list" > /etc/apt/sources.list
sed -i "s/CODENAME/$(lsb_release -cs)/" /etc/apt/sources.list
rm -fr /etc/apt/sources.list.d/*

# Upgrade base system packages
#-----------------------------------------------------------------------------------------
apt update -yqq && apt -yqq full-upgrade && apt -yqq autoremove

# Install core packages
#-----------------------------------------------------------------------------------------
echo -e "\n${BLUE}Installing core packages...${NOCOLOR}"
apt -yqq install screen elinks lsof dirmngr gnupg debconf-utils build-essential gcc make \
cmake whois rsync dh-autoreconf screenfetch jpegoptim optipng apache2-utils sshpass xsel \
pv libpq-dev python3 python3-dev python3-wheel python3-pip python3-setuptools python3-venv \
python3-virtualenv python3-psycopg2 virtualenv ansible
