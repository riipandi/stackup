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
if [ $(crudini --get $ROOT/config.ini setup ready) != "yes" ]; then
    source "$ROOT/wizard.sh"
fi

# Preparing for installation
#-----------------------------------------------------------------------------------------
COUNTRY=`crudini --get $ROOT/config.ini system country`
if [ $COUNTRY == "ID" ] ; then
    cat $ROOT/repository/sources-id.list > /etc/apt/sources.list
elif [ $COUNTRY == "SG" ] ; then
    cat $ROOT/repository/sources-sg.list > /etc/apt/sources.list
else
    cat $ROOT/repository/sources.list > /etc/apt/sources.list
fi
sed -i "s/CODENAME/$(lsb_release -cs)/" /etc/apt/sources.list
apt update ; apt full-upgrade -y ; apt autoremove -y

# Preparing for installation
#-----------------------------------------------------------------------------------------
echo ; read -p "Press enter to begin installation..."

echo -e "\nInstalling basic packages..."
apt install -y sudo nano figlet elinks pwgen curl lsof whois dirmngr \
gcc make cmake build-essential software-properties-common debconf-utils \
apt-transport-https perl binutils dnsutils nscd ftp zip unzip bsdtar pv \
dh-autoreconf rsync screen screenfetch ca-certificates resolvconf nmap \
nikto speedtest-cli xmlstarlet optipng jpegoptim sqlite3 s3cmd
python-virtualenv python3-virtualenv virtualenv

# Copy snippet to local bin
cp $ROOT/snippets/* /usr/local/bin/
chown -R root: /usr/local/bin/*
chmod a+x /usr/local/bin/*

# Ask for creating new user
#-----------------------------------------------------------------------------------------
read -ep "Create a new sudo user?      [Y/n] : " CreateUserSudo
[[ ! "${CreateUserSudo,,}" =~ ^(yes|y)$ ]] || CallScript 'snippets/create-sudoer'

read -ep "Create user for deployer?    [Y/n] : " CreateUserDeployer
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
