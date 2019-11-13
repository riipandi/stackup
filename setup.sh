#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
NOCOLOR='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;33m'
BLUE='\033[0;34m'

#----------------------------------------------------------------------------------
# StackUp Installation Script.
#----------------------------------------------------------------------------------

# Define working directory
ROOTDIR=$(dirname "$(readlink -f "$0")")
CLONE_DIR=/usr/src/stackup

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
    echo -e "${GREEN}"
    read -p "Press [Enter] to Continue or [Ctrl+C] to Cancel..."
    echo -e "${NOCOLOR}"
fi

# Install required dependencies
#----------------------------------------------------------------------------------
echo -e "\n${OK}Installing required dependencies...${NC}"
cat > /etc/apt/apt.conf.d/99force-config <<EOF
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
}
EOF
apt update -qq && apt -y full-upgrade
apt -yqq install lsb-release apt-transport-https software-properties-common
apt -yqq install sudo wget curl git crudini openssl figlet perl bsdtar
apt -y autoremove

# Clone setup file and begin instalation process
#-----------------------------------------------------------------------------------------
if [ ! -z "$1" ] && [ "$1" == "--dev" ]; then CHANNEL="dev" ; else CHANNEL="stable" ; fi

if ! [ $(pwd) == $ROOTDIR ]; then
    WORKDIR=$CLONE_DIR
    [[ ! -d $WORKDIR ]] || rm -fr $WORKDIR && rm -fr /tmp/stackup-*
    if [ $CHANNEL == "dev" ]; then
        git clone https://github.com/riipandi/stackup $WORKDIR
    else
        project="https://api.github.com/repos/riipandi/stackup/releases/latest"
        release=`curl -s $project | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`
        curl -fsSL https://github.com/riipandi/stackup/archive/$release.zip | bsdtar -xvf- -C /tmp
        version=`echo "${release/v/}"` ; mv /tmp/stackup-$version $WORKDIR
    fi
    find $WORKDIR/ -type f -name '.git*' -exec rm -fr {} \;
else
    WORKDIR=$ROOTDIR
fi

# Fix setup script permission
find $WORKDIR/ -type f -name '*.py' -exec chmod +x {} \;
find $WORKDIR/ -type f -name '*.sh' -exec chmod +x {} \;

# Run setup wizard
#----------------------------------------------------------------------------------
echo -e "\n${GREEN}------------------------------------------------------${NOCOLOR}"
echo -e "${GREEN}--- Starting StackUp installation wizard${NOCOLOR}"
echo -e "${GREEN}------------------------------------------------------\n${NOCOLOR}"
read -ep "Do you want customize installation ?   y/n : " -i "n" answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    bash "$WORKDIR/install/common.sh"
    bash "$WORKDIR/install/custom.sh"
else
    bash "$WORKDIR/install/common.sh"
    bash "$WORKDIR/install/essential.sh"
fi
