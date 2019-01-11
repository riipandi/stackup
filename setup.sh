#!/bin/bash

PWD=$(dirname "$(readlink -f "$0")")

if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

echo -e "\nPreparing for installation, installing dependencies..."

apt update -qq ; apt -yqq full-upgrade
apt -yqq install sudo git curl crudini openssl

workdir="/usr/src/lempstack"

if [[ -d $workdir ]]; then rm -fr $workdir ; fi

git clone https://github.com/riipandi/lempstack $workdir ; cd $_

find $PWD/snippets/ -type f -exec chmod +x {} \;
find . -type f -name '*.sh' -exec chmod +x {} \;
find . -type f -name '.git*' -exec rm -fr {} \;
rm -fr /etc/apt/sources.list.d/*

echo -e "\nStarting the installer..."

bash $PWD/install.sh
