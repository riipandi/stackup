#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PARENT=$(dirname `dirname $(readlink -f $0)`) || PARENT=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

read -ep "Install PHP 7.3 ?                       y/n : " -i "yes" php_73
read -ep "Install PHP 7.2 ?                       y/n : " -i "yes" php_72
read -ep "Install PHP 5.6 ?                       y/n : " -i "yes" php_56

