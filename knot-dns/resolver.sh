#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

echo "deb https://packages.sury.org/knot-resolver/ `lsb_release -cs` main" > /etc/apt/sources.list.d/knot-resolver.list
curl -sS https://packages.sury.org/knot-resolver/apt.gpg | apt-key add - && apt update

apt -y install knot-resolver

# source $ROOT/knot-dns/configure.sh
