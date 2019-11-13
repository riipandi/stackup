#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
NOCOLOR='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;33m'
BLUE='\033[0;34m'
CURRENT=$(dirname $(readlink -f $0))
[ -z $ROOTDIR ] && PWD=$(dirname `dirname $CURRENT`) || PWD=$ROOTDIR

#-----------------------------------------------------------------------------------------
echo -e "\n${BLUE}Installing Nodejs + Yarn...${NOCOLOR}"
#-----------------------------------------------------------------------------------------
! [[ -z $(which nodejs) ]] && echo -e "${BLUE}Already installed...${NOCOLOR}" && exit 1

# Install packages
#-----------------------------------------------------------------------------------------
cat > /etc/apt/sources.list.d/nodejs.list <<EOF
deb https://deb.nodesource.com/node_12.x `lsb_release -cs` main
deb https://dl.yarnpkg.com/debian/ stable main
EOF
curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - &>/dev/null
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - &>/dev/null

apt update -qq ; apt full-upgrade -yqq ; apt -yqq install nodejs yarn
