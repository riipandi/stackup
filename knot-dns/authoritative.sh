#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

echo "deb https://packages.sury.org/knot/ `lsb_release -cs` main" > /etc/apt/sources.list.d/knot-dns.list
curl -sS https://packages.sury.org/knot/apt.gpg | apt-key add - && apt update

apt -yqq install python-configparser python-lmdb knot knot-dnsutils

# source $ROOT/knot-dns/configure.sh
