#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

ROOT=$(dirname "$(readlink -f "$0")")

# Some functions
#-----------------------------------------------------------------------------------------
CallScript() {
    bash $ROOT/$1
}

InstallPackage() {
    [[ $(crudini --get $ROOT/config.ini $1 $2) != "yes" ]] || CallScript $3
}

# Initial setup
#-----------------------------------------------------------------------------------------
[[ $(crudini --get $ROOT/config.ini setup ready) == "yes" ]] || bash $ROOT/wizard.sh

# Preparing for installation
#-----------------------------------------------------------------------------------------
echo ; read -p "Press enter to begin installation..."

echo -e "\nInstalling basic packages..."
apt install -y sudo nano figlet elinks pwgen curl lsof whois dirmngr \
gcc make cmake build-essential software-properties-common debconf-utils \
apt-transport-https perl binutils dnsutils nscd ftp zip unzip bsdtar pv \
dh-autoreconf rsync screen screenfetch ca-certificates resolvconf nmap \
nikto speedtest-cli xmlstarlet optipng jpegoptim sqlite3 s3cmd

# Copy snippet to local bin
cp $ROOT/snippets/* /usr/local/bin/
chown -R root: /usr/local/bin/*
chmod a+x /usr/local/bin/*

# Ask for creating new user
#-----------------------------------------------------------------------------------------
read -ep "Do you want to create a new user?        [Y/n] : " CreateUserSudo
[[ ! "${CreateUserSudo,,}" =~ ^(yes|y)$ ]] || CallScript 'snippets/create-sudoer'

read -ep "Do you want to create deployer user?     [Y/n] : " CreateUserDeployer
[[ ! "${CreateUserDeployer,,}" =~ ^(yes|y)$ ]] || CallScript 'snippets/create-buddy'

# Install and configure packages
#-----------------------------------------------------------------------------------------
InstallPackage 'system' 'swap_enable' 'system/swap-memory.sh'

CallScript 'system/set-openssh.sh'
CallScript 'system/set-network.sh'

CallScript 'nginx/setup.sh'
CallScript 'nginx/config.sh'

CallScript 'interpreter/setup-php.sh'
CallScript 'interpreter/setup-python.sh'
InstallPackage 'nodejs' 'install' 'interpreter/setup-nodejs.sh'

InstallPackage 'redis' 'install' 'database/redis-server.sh'

CallScript 'database/setup.sh'

# Cleanup
#-----------------------------------------------------------------------------------------
echo -e "\nCleaning up installation...\n"
apt -y autoremove && apt clean && netstat -pltn

echo -e "\nCongratulation, server stack has been installed.\n"
if [[ `crudini --get $ROOT/config.ini system reboot` == "yes" ]] ; then
    echo "System will reboot in 5 seconds..."
    sleep 5s; shutdown -r now
fi
