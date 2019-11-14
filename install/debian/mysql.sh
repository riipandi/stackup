#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

# Determine root directory
[ -z $ROOTDIR ] && PWD=$(dirname `dirname $(dirname $(readlink -f $0))`) || PWD=$ROOTDIR

# Common global variables
source "$PWD/common.sh"

#-----------------------------------------------------------------------------------------
msgSuccess "\n--- Installing MySQL"
#-----------------------------------------------------------------------------------------
! [[ -z $(which mysql) ]] && msgError "Already installed..." && exit 1

# Install packages
#-----------------------------------------------------------------------------------------
apt update -qq ; apt full-upgrade -yqq ; apt -yq install xxxxxxxxxxxxxxxx

# Configure packages
#-----------------------------------------------------------------------------------------
