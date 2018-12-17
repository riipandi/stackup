#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

SetConfigSetup() {
    crudini --set $ROOT/install.ini $1 $2 $3
}

GetConfigSetup() {
    crudini --get $ROOT/install.ini $1 $2
}
