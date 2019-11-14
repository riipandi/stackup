#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

# Determine root directory
[ -z $ROOTDIR ] && PWD=$(dirname `dirname $(dirname $(readlink -f $0))`) || PWD=$ROOTDIR

# Common global variables
source "$PWD/common.sh"

#-----------------------------------------------------------------------------------------
msgSuccess "\n--- Installing Nodejs and Yarn"
#-----------------------------------------------------------------------------------------
[[ -z $(which nodejs) ]] || msgError "Already installed..." && exit 1

# Install packages
#-----------------------------------------------------------------------------------------
cat > /etc/apt/sources.list.d/nodejs.list <<EOF
deb https://deb.nodesource.com/node_12.x `lsb_release -cs` main
deb https://dl.yarnpkg.com/debian/ stable main
EOF
curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - &>/dev/null
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - &>/dev/null

apt update -qq ; apt full-upgrade -yqq ; apt -yqq install nodejs yarn
