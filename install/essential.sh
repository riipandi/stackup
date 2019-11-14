#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOTDIR ] && PWD=$(dirname $(dirname $(readlink -f $0))) || PWD=$ROOTDIR
source "$PWD/common.sh"

# Determine current distro
distro=`echo ${osDistro} | tr '[:upper:]' '[:lower:]'`

#----------------------------------------------------------------------------------
# --
#----------------------------------------------------------------------------------

# Setup core packages
bash "$PWD/install/$distro/core.sh"

# Setup MariaDB
bash "$PWD/install/$distro/mariadb.sh"

# Setup Nginx
bash "$PWD/install/$distro/nginx.sh"

# Setup PHP-FPM
bash "$PWD/install/$distro/phpfpm.sh"

# Setup Nodejs + Yarn
bash "$PWD/install/$distro/nodejs.sh"

# Setup phpMyAdmin
bash "$PWD/install/$distro/phpmyadmin.sh"
