#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

WORKDIR="/usr/src/lempstack"

# Set default resolver
#-----------------------------------------------------------------------------------------
rm -f /etc/resolv.conf
touch /etc/resolv.conf
{
    echo 'nameserver 1.1.1.1'
    echo 'nameserver 209.244.0.3'
} > /etc/resolv.conf

# Change mirror repository
#-----------------------------------------------------------------------------------------
COUNTRY=`wget -qO- ipapi.co/json | grep '"country":' | sed -E 's/.*"([^"]+)".*/\1/'`

echo -e "\nPreparing for installation, installing dependencies..."

apt update -qq
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
apt -yqq install sudo git curl crudini openssl figlet perl ; apt autoremove -y

# Clone setup file and begin instalation process
#-----------------------------------------------------------------------------------------
if [ -d $WORKDIR ]; then rm -fr $WORKDIR ; fi

git clone https://github.com/riipandi/lempstack $WORKDIR ; cd $_

crudini --set $WORKDIR/config.ini 'system' 'country' $COUNTRY
find $WORKDIR/snippets/ -type f -exec chmod +x {} \;
find . -type f -name '*.sh' -exec chmod +x {} \;
find . -type f -name '.git*' -exec rm -fr {} \;
rm -fr /etc/apt/sources.list.d/*

echo -e "\nStarting the installer..."

crudini --set $WORKDIR/config.ini 'setup' 'ready' 'no'

bash $WORKDIR/install.sh
