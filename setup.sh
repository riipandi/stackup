#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

if [ ! -z "$1" ] && [ "$1" == "--dev" ]; then CHANNEL="dev" ; else CHANNEL="stable" ; fi

PWD=$(dirname "$(readlink -f "$0")")

WORKDIR="/usr/src/lempstack"

# Set default resolver
#-----------------------------------------------------------------------------------------
rm -f /etc/resolv.conf ; touch /etc/resolv.conf
echo 'nameserver 1.1.1.1' > /etc/resolv.conf
echo 'nameserver 209.244.0.3' >> /etc/resolv.conf

# Change mirror repository
#-----------------------------------------------------------------------------------------
COUNTRY=`wget -qO- ipapi.co/json | grep '"country":' | sed -E 's/.*"([^"]+)".*/\1/'`

echo -e "\nPreparing for installation, installing dependencies..."

wget https://raw.githubusercontent.com/riipandi/lempstack/master/repository/sources.list -qO /etc/apt/sources.list
sed -i "s/CODENAME/$(lsb_release -cs)/" /etc/apt/sources.list

apt update -qq
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
apt -yqq install sudo git curl crudini openssl figlet perl ; apt autoremove -y

# Clone setup file and begin instalation process
#-----------------------------------------------------------------------------------------
[[ ! -d $WORKDIR ]] || rm -fr $WORKDIR && rm -fr /tmp/lempstack-*

if [ $CHANNEL == "dev" ]
    git clone https://github.com/riipandi/lempstack $WORKDIR
else
    project="https://api.github.com/repos/riipandi/lempstack/releases/latest"
    release=`curl -s $project | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`
    curl -fsSL https://github.com/riipandi/lempstack/archive/$release.zip | bsdtar -xvf- -C /tmp
    version=`echo "${release/v/}"` ; mv /tmp/lempstack-$version $WORKDIR
fi

crudini --set $WORKDIR/config.ini 'system' 'country' $COUNTRY
find $WORKDIR/snippets/ -type f -exec chmod +x {} \;
find $WORKDIR/ -type f -name '*.sh' -exec chmod +x {} \;
find $WORKDIR/ -type f -name '.git*' -exec rm -fr {} \;
rm -fr /etc/apt/sources.list.d/*

echo -e "\nStarting the installer..."

crudini --set $WORKDIR/config.ini 'setup' 'ready' 'no'

(exec "$WORKDIR/install.sh")
