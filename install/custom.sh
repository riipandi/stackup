#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOTDIR ] && PWD=$(dirname $(dirname $(readlink -f $0))) || PWD=$ROOTDIR
source "$PWD/common.sh"

#----------------------------------------------------------------------------------
# --
#----------------------------------------------------------------------------------

msgContinue
