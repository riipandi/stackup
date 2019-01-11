#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

[ -z $ROOT ] && PARENT=$(dirname "$(readlink -f "$0")") || PARENT=$ROOT

GET_ENGINE=`crudini --get $PARENT/config.ini mysql engine`
GET_VERSION=`crudini --get $PARENT/config.ini mysql version`

# Install MySQL and phpMyAdmin
if [ $(crudini --get $PARENT/config.ini mysql install) == "yes" ] ; then
    if [ $GET_ENGINE == "mariadb" ] ; then
        source $PARENT/database/mariadb.sh
    else
        if [ $GET_VERSION == "5.7" ] ; then
            source $PARENT/database/mysql57.sh
        else
            source $PARENT/database/mysql80.sh
        fi
    fi
    source $PARENT/database/phppgadmin.sh
fi

# Install POstgreSQL and phpPgAdmin
if [ $(crudini --get $PARENT/config.ini postgres install) == "yes" ] ; then
    source $PARENT/database/postgresql.sh
    source $PARENT/database/phppgadmin.sh
fi
