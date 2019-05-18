#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PWD=$(dirname `dirname $(readlink -f $0)`) || PWD=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

read -ep "Install NodeJS and Yarn ?                   y/n : " -i "y" answer

if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    # NodeJS LTS
    echo "deb https://deb.nodesource.com/node_10.x `lsb_release -cs` main" > /etc/apt/sources.list.d/nodejs.list
    curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -

    # Yarn stable
    echo 'deb https://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -

    # Install packages
    apt update ; apt -y full-upgrade ; apt -y install nodejs yarn
fi
