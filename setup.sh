#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
ROOT=$(dirname "$(readlink -f "$0")")
#------------------------------------------------------------------------------
# StackUp Installation Script.
#------------------------------------------------------------------------------

# Set working directory
WORKDIR=$ROOT

# Check OS support
distr=`echo $(lsb_release -i | cut -d':' -f 2)`
osver=`echo $(lsb_release -c | cut -d':' -f 2)`
if ! [[ $distr == "Ubuntu" && $osver =~ ^(xenial|bionic)$ ]]; then
    echo "$(tput setaf 1)"
    echo "**************************************************************"
    echo "****   This OS distribution is not supported by StackUp   ****"
    echo "**************************************************************"
    echo "$(tput sgr0)"
    exit 1
else
    read -p "Press [Enter] to Continue or [Ctrl+C] to Cancel..."
fi

# Install required dependencies
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Installing required dependencies...${NC}"
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
apt update -qq ; apt -yqq install git curl crudini openssl figlet perl python-click ; apt autoremove -y

# Clone setup file and begin instalation process
#-----------------------------------------------------------------------------------------
# if [ ! -z "$1" ] && [ "$1" == "--dev" ]; then CHANNEL="dev" ; else CHANNEL="stable" ; fi
# [[ ! -d $WORKDIR ]] || rm -fr $WORKDIR && rm -fr /tmp/stackup-*

# if [ $CHANNEL == "dev" ]; then
#     git clone https://github.com/riipandi/stackup $WORKDIR
# else
#     project="https://api.github.com/repos/riipandi/stackup/releases/latest"
#     release=`curl -s $project | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`
#     curl -fsSL https://github.com/riipandi/stackup/archive/$release.zip | bsdtar -xvf- -C /tmp
#     version=`echo "${release/v/}"` ; mv /tmp/stackup-$version $WORKDIR
# fi

find $WORKDIR/ -type f -name '*.py' -exec chmod +x {} \;
find $WORKDIR/ -type f -name '*.sh' -exec chmod +x {} \;
find $WORKDIR/ -type f -name '.git*' -exec rm -fr {} \;
rm -fr /etc/apt/sources.list.d/*

# Begin installation process
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Starting StackUp installer...${NC}"
read -p "Press [Enter] to Continue or [Ctrl+C] to Cancel..."
crudini --set $WORKDIR/config/stackup.ini 'setup' 'ready' 'no'

# Basic setup
#-----------------------------------------------------------------------------------------
bash "$WORKDIR/setup/common.sh"
bash "$WORKDIR/setup/config-user.sh"
bash "$WORKDIR/setup/config-ssh.sh"
bash "$WORKDIR/setup/config-network.sh"
bash "$WORKDIR/setup/config-swap.sh"
bash "$WORKDIR/setup/config-telegram.sh"

# Install PHP
#-----------------------------------------------------------------------------------------

# Install Nginx
#-----------------------------------------------------------------------------------------

# Install Nginx
#-----------------------------------------------------------------------------------------

# Install Nginx
#-----------------------------------------------------------------------------------------

# Install Nginx
#-----------------------------------------------------------------------------------------

# Install Nginx
#-----------------------------------------------------------------------------------------

# Install Nginx
#-----------------------------------------------------------------------------------------

# Install Nginx
#-----------------------------------------------------------------------------------------

# Install Nginx
#-----------------------------------------------------------------------------------------

# Install Nginx
#-----------------------------------------------------------------------------------------

# Install Nginx
#-----------------------------------------------------------------------------------------

# Install StackUp cli utility
#-----------------------------------------------------------------------------------------
# sudo -H pip install .

echo -e "\n${OK}Installation has been finish...${NC}\n"
