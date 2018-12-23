#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

echo "deb https://packages.sury.org/wireguard/ `lsb_release -cs` main" > /etc/apt/sources.list.d/wireguard.list
curl -sS https://packages.sury.org/wireguard/apt.gpg | apt-key add - && apt update

apt -yqq install wireguard wireguard-dkms wireguard-tools

# source $ROOT/wireguard/configure.sh
