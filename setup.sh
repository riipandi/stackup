#!/usr/bin/env bash

PWD=$(dirname "$(readlink -f "$0")")

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

apt update -qq
apt -yqq full-upgrade
apt -yqq install git curl

cd /usr/src
rm -fr /usr/src/lempstack
rm -fr /etc/apt/sources.list.d/*

git clone https://github.com/riipandi/lempstack /usr/src/lempstack ; cd $_

find . -type f -name '*.sh' -exec chmod +x {} \;
find . -type f -name '.git*' -exec rm -fr {} \;

bash $PWD/install.sh
