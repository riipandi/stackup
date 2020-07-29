#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

# Determine root directory
[ -z $ROOTDIR ] && PWD=$(dirname `dirname $(dirname $(readlink -f $0))`) || PWD=$ROOTDIR

# Common global variables
source "$PWD/common.sh"

# Determine os codename
osver=`echo ${osVersion} | tr '[:upper:]' '[:lower:]'`

#-----------------------------------------------------------------------------------------
msgSuccess "\n--- Installing Apache HTTPd"
#-----------------------------------------------------------------------------------------
# LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/apache2 && apt -y full-upgrade
apt -y install apache2 apache2-utils
