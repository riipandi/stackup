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

# Common functions
#----------------------------------------------------------------------------------
msgNotSupported() {
    echo "$(tput setaf 1)"
    echo "************************************************************"
    echo "*****    This distribution not supported by StackUp    *****"
    echo "************************************************************"
    echo "$(tput sgr0)"
}

msgContinue() {
    echo -e "${GREEN}"
    read -p "Press [Enter] to Continue or [Ctrl+C] to Cancel..."
    echo -e "${NOCOLOR}"
}

# Check OS support
#----------------------------------------------------------------------------------
distr=`echo $(lsb_release -i | cut -d':' -f 2)`
osver=`echo $(lsb_release -c | cut -d':' -f 2)`

if ! [[ $distr == "Debian" || $distr == "Ubuntu" ]]; then
    msgNotSupported && exit 1
else
    if [[ $distr == "Debian" && ! $osver =~ ^(stretch|buster)$ ]]; then
        msgNotSupported && exit 1
    elif [[ $distr == "Ubuntu" && ! $osver =~ ^(xenial|bionic)$ ]]; then
        msgNotSupported && exit 1
    fi
    msgContinue
fi

# Preparing setup
#----------------------------------------------------------------------------------
cat > /etc/apt/apt.conf.d/99force-config <<EOF
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
}
EOF

# Update base system packages.
# -mmin -360 finds files that have a change time in the last 6 hours.
# You can use -mtime if you care about longer times (days).
if [ -z "$(find -H /var/lib/apt/lists -maxdepth 0 -mtime -360)" ]; then
    echo -e "${BLUE}Updating base system packages...\n${NOCOLOR}"
    apt update -qq && apt -yqq full-upgrade && apt -y autoremove
fi

# Install required dependencies
if [ -z $(which crudini) ]; then
    echo -e "${BLUE}\nInstalling required dependencies...\n${NOCOLOR}"
    apt -yqq install sudo perl lsb-release apt-transport-https software-properties-common
    apt -yqq install wget curl git zip unzip jq crudini openssl ca-certificates bsdtar
    apt -yqq install nano figlet dnsutils binutils net-tools pwgen openssh-server htop
fi

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

[[ -f "$WORKDIR/stackup.ini" ]] || touch "$WORKDIR/stackup.ini"
touch /tmp/stackup-install.log && bash "$WORKDIR/install/common.sh"

echo -e "\n${GREEN} You can choose between automatic installation or custom installation."
echo -e " By default this script will install latest stable version of Nginx,"
echo -e " PHP, MariaDB, and Nodejs + Yarn.${NOCOLOR}\n"

read -ep "Do you want to customize installation ?     y/n : " -i "n" answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    bash "$WORKDIR/install/custom.sh"
else
    bash "$WORKDIR/install/essential.sh"
fi

# Configure toolkit
#----------------------------------------------------------------------------------
read -ep "Do you want to use StackUp utilities ?      y/n : " -i "y" answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    find $WORKDIR/toolkit/. -type f -name '*.sh' | while read f; do mv "$f" "${f%.sh}"; done
    find $WORKDIR/toolkit/. -type f -exec chmod 0777 {} \;
    cp $WORKDIR/toolkit/* /usr/local/bin/.
fi

# Cleanup and save some important information
#-----------------------------------------------------------------------------------------
echo -e "\n${GREEN}Cleaning up installation...${NOCOLOR}\n"
apt -yqq autoremove && apt clean
echo -e "\n${GREEN}------------------------------------------------------${NOCOLOR}"
echo -e "${GREEN}--- Installation has been finish!${NOCOLOR}"
echo -e "${GREEN}------------------------------------------------------\n${NOCOLOR}"
echo & cat /tmp/stackup-install.log
echo & netstat -pltnu46
