#!/bin/bash

PWD=$(dirname "$(readlink -f "$0")")
PARENT=$(dirname $PWD)

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

postgresql-{10,client-10}

sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$DB_ROOT_PASS'"