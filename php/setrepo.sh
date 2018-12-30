#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi


## Setup PHP repo
file="/etc/apt/sources.list.d/sury-php.list"

echo "deb https://packages.sury.org/php/ `lsb_release -cs` main" > $file
curl -sS https://packages.sury.org/php/apt.gpg | apt-key add -
apt update
