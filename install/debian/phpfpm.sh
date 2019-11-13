#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
NOCOLOR='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;33m'
BLUE='\033[0;34m'
CURRENT=$(dirname $(readlink -f $0))
[ -z $ROOTDIR ] && PWD=$(dirname `dirname $CURRENT`) || PWD=$ROOTDIR

#-----------------------------------------------------------------------------------------
echo -e "\n${BLUE}Installing PHP-FPM...${NOCOLOR}"
#-----------------------------------------------------------------------------------------
! [[ -z $(which php) ]] && echo -e "${BLUE}Already installed...${NOCOLOR}" && exit 1

# Install packages
#-----------------------------------------------------------------------------------------
apt update -qq ; apt full-upgrade -yqq ; apt -yqq install xxxxxxxxxxxxxxxx

# Configure packages
#-----------------------------------------------------------------------------------------

# Default PHP-FPM on Nginx configuration
#-----------------------------------------------------------------------------------------
# find /etc/nginx/stubs/ -type f -exec sed -i "s/php.*.-fpm/php\/php${default_php}-fpm/g" {} +
# sed -i "s/php.*.-fpm/php\/php${default_php}-fpm/g" /etc/nginx/conf.d/default.conf
# systemctl restart nginx
