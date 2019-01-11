#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

PWD=$(dirname "$(readlink -f "$0")")
PARENT=$(dirname "$PWD")

GET_ENGINE=`crudini --get $ROOT/config.ini mysql engine`
GET_VERSION=`crudini --get $ROOT/config.ini mysql version`

# Install MySQL and phpMyAdmin
if [ $(crudini --get $ROOT/config.ini mysql install) == "yes" ] ; then
    if [ $GET_ENGINE == "mariadb" ] ; then
        source $ROOT/database/mariadb.sh
    else
        if [ $GET_VERSION == "5.7" ] ; then
            source $ROOT/database/mysql57.sh
        else
            source $ROOT/database/mysql80.sh
        fi
    fi
    source $ROOT/database/phppgadmin.sh
fi

# Install POstgreSQL and phpPgAdmin
if [ $(crudini --get $ROOT/config.ini postgres install) == "yes" ] ; then
    source $ROOT/database/postgresql.sh
    source $ROOT/database/phppgadmin.sh
fi
