#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
NOCOLOR='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;33m'
BLUE='\033[0;34m'
CURRENT=$(dirname $(readlink -f $0))
[ -z $ROOTDIR ] && PWD=$(dirname $CURRENT) || PWD=$ROOTDIR

# Determine current distro
distro=`echo $(lsb_release -i | cut -d':' -f 2) | tr '[:upper:]' '[:lower:]'`

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
