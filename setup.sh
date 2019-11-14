#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

# Define working directory
ROOTDIR=$(dirname "$(readlink -f "$0")")
CLONE_DIR=/usr/src/stackup

source "$ROOTDIR/common.sh"

#----------------------------------------------------------------------------------
# StackUp Installation Script.
#----------------------------------------------------------------------------------

# Check OS support
msgNotSupported() {
    echo "$(tput setaf 1)"
    echo "************************************************************"
    echo "*****    This distribution not supported by StackUp    *****"
    echo "************************************************************"
    echo "$(tput sgr0)"
}

if ! [[ $osDistro == "Debian" || $osDistro == "Ubuntu" ]]; then
    msgNotSupported && exit 1
else
    if [[ $osDistro == "Debian" && ! $osVersion =~ ^(stretch|buster)$ ]]; then
        msgNotSupported && exit 1
    elif [[ $osDistro == "Ubuntu" && ! $osVersion =~ ^(xenial|bionic)$ ]]; then
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
    msgInfo "\nUpdating base system packages..."
    pkgUpgrade
fi

# Install required dependencies
if [ -z $(which crudini) ]; then
    msgInfo "\nInstalling required dependencies..."
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
msgSuccess "----------------------------------------------------------"
msgSuccess "---        Starting StackUp installation wizard        ---"
msgSuccess "----------------------------------------------------------"
[[ -f "$WORKDIR/stackup.ini" ]] || touch "$WORKDIR/stackup.ini"
[[ -f "${logFile}" ]] || touch touch ${logFile}
bash "$WORKDIR/install/common.sh"

msgSuccess "\n You can choose between automatic installation or custom installation."
msgSuccess " By default this script will install latest stable version of PHP FPM,"
msgSuccess " MariaDB, Nodejs + Yarn, and Nginx mainline.\n"

read -ep "Do you want to customize installation?      y/n : " -i "n" answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    bash "$WORKDIR/install/custom.sh"
else
    bash "$WORKDIR/install/essential.sh"
fi

# Ask to install utilities
#----------------------------------------------------------------------------------
if [ ! -f "/usr/local/bin/pkg-update" ]; then
    echo && read -ep "Do you want to use StackUp utilities?       y/n : " -i "y" answer
    if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
        find $WORKDIR/toolkit/. -type f -name '*.sh' | while read f; do mv "$f" "${f%.sh}"; done
        find $WORKDIR/toolkit/. -type f -exec chmod 0777 {} \;
        cp $WORKDIR/toolkit/* /usr/local/bin/.
    fi
fi

# Cleanup and display finish message
#-----------------------------------------------------------------------------------------
msgSuccess "\n--- Cleaning up installation" && pkgClean
echo "$(tput setaf 1)"
echo "***************************************************************"
echo "*****   Congratulation, installation has been finished!   *****"
echo "***************************************************************"
echo "$(tput sgr0)"
echo & cat ${logFile}
echo & netstat -pltnu
