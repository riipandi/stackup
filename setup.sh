#!/usr/bin/env bash

PWD=$(dirname "$(readlink -f "$0")")

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

apt update -qq
apt -yqq full-upgrade
apt -yqq install git curl

outputdir="/usr/src/lempstack"

if [[ ! -d $outputdir ]]; then
    git clone https://github.com/riipandi/lempstack $outputdir ; cd $_
    find . -type f -name '*.sh' -exec chmod +x {} \;
    find . -type f -name '.git*' -exec rm -fr {} \;
    rm -fr /etc/apt/sources.list.d/*
    bash $PWD/install.sh
else
    echo -e "Directory $outputdir already exists, please remove first!"
fi
