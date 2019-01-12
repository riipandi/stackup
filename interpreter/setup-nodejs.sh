#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

[ -z $ROOT ] && PARENT=$(dirname "$(readlink -f "$0")") || PARENT=$ROOT

# Install packages
#-----------------------------------------------------------------------------------------

echo "deb https://deb.nodesource.com/node_10.x `lsb_release -cs` main" > /etc/apt/sources.list.d/nodejs.list
curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -

echo 'deb https://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -

apt update ; apt full-upgrade -y ; apt -y install nodejs yarn
