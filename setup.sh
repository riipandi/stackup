#!/bin/bash
# StackUp Installation Script.

# Check OS support
distr=`echo $(lsb_release -i | cut -d':' -f 2)`
osver=`echo $(lsb_release -c | cut -d':' -f 2)`
if ! [[ $distr == "Ubuntu" && $osver =~ ^(xenial|bionic)$ ]]; then
    echo "$(tput setaf 1)"
    echo "***************************************************************************"
    echo "****  This OS is not supported by StackUp and could not work properly  ****"
    echo "***************************************************************************"
    echo "$(tput sgr0)"
    read -p "Press [Enter] key to Continue or [Ctrl+C] to Cancel..."
fi
# Check for sudo/root privileges
if ! $(groups $USERNAME | grep &>/dev/null '\bsudo\b' || groups $USERNAME | grep &>/dev/null '\broot\b'); then
    echo "$(tput setaf 1)"
    echo "****  [ERROR] sudo/root privileges are required to install StackUp ****"
    echo "$(tput sgr0)"
    read -p "Press [Enter] key to Continue or [Ctrl+C] to Cancel..."
fi

# Check installation source
if [ ! -z "$1" ] && [ "$1" == "--dev" ]; then CHANNEL="dev" ; else CHANNEL="stable" ; fi

PWD=$(dirname "$(readlink -f "$0")")

WORKDIR="/usr/src/stackup"

# Set default resolver
#-----------------------------------------------------------------------------------------
rm -f /etc/resolv.conf ; touch /etc/resolv.conf
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 209.244.0.3" >> /etc/resolv.conf

# Change mirror repository
#-----------------------------------------------------------------------------------------
COUNTRY=`wget -qO- ipapi.co/json | grep '"country":' | sed -E 's/.*"([^"]+)".*/\1/'`

[[ $CHANNEL = "dev" ]] && MSG=" (master branch)"

echo -e "\nPreparing for installation$MSG, installing dependencies$MSG..."

wget https://raw.githubusercontent.com/riipandi/stackup/master/repository/sources.list -qO /etc/apt/sources.list
sed -i "s/CODENAME/$(lsb_release -cs)/" /etc/apt/sources.list

apt update -qq
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
apt -yqq install sudo git curl crudini openssl figlet perl ; apt autoremove -y

# Clone setup file and begin instalation process
#-----------------------------------------------------------------------------------------
[[ ! -d $WORKDIR ]] || rm -fr $WORKDIR && rm -fr /tmp/stackup-*

if [ $CHANNEL == "dev" ]; then
    git clone https://github.com/riipandi/stackup $WORKDIR
else
    project="https://api.github.com/repos/riipandi/stackup/releases/latest"
    release=`curl -s $project | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`
    curl -fsSL https://github.com/riipandi/stackup/archive/$release.zip | bsdtar -xvf- -C /tmp
    version=`echo "${release/v/}"` ; mv /tmp/stackup-$version $WORKDIR
fi

crudini --set $WORKDIR/config.ini 'system' 'country' $COUNTRY
find $WORKDIR/snippets/ -type f -exec chmod +x {} \;
find $WORKDIR/ -type f -name '*.sh' -exec chmod +x {} \;
find $WORKDIR/ -type f -name '.git*' -exec rm -fr {} \;
rm -fr /etc/apt/sources.list.d/*

echo -e "\nStarting the installer..."

crudini --set $WORKDIR/config.ini 'setup' 'ready' 'no'

bash "$WORKDIR/install.sh"
