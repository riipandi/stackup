#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PWD=$(dirname `dirname $(readlink -f $0)`) || PWD=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

touch "$PWD/stackup.ini"
if [ -f "$PWD/stackup.ini" ]; then
    [[ $(cat "$PWD/stackup.ini" | grep -c "nodejs_install") -eq 1 ]] && nodejs_install=$(crudini --get $PWD/stackup.ini '' 'nodejs_install')
    [[ -z "$nodejs_install" ]] && read -ep "Install NodeJS and Yarn ?                   y/n : " -i "y" nodejs_install
fi

if [[ "${nodejs_install,,}" =~ ^(yes|y)$ ]] ; then
    echo -e "\n${OK}Installing Nodejs and Yarn...${NC}\n"
    echo "deb https://deb.nodesource.com/node_10.x `lsb_release -cs` main" > /etc/apt/sources.list.d/nodejs.list
    echo 'deb https://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list
    curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    apt update ; apt -y full-upgrade ; apt -y install nodejs yarn
fi
