#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

# Define working directory
ROOTDIR=$(dirname "$(readlink -f "$0")")
CLONE_DIR=/usr/src/stackup

if ! [ $(pwd) == $ROOTDIR ]; then
    wget -qO /tmp/stackup-common.sh https://raw.githubusercontent.com/riipandi/stackup/master/common.sh
    source "/tmp/stackup-common.sh"
else
    source "$ROOTDIR/common.sh"
fi

#----------------------------------------------------------------------------------
# StackUp Updater Script.
#----------------------------------------------------------------------------------

# Cleanup and display finish message
#-----------------------------------------------------------------------------------------
echo "$(tput setaf 1)"
echo "***************************************************************"
echo "*****     Congratulation, StackUp hasbeed updated!        *****"
echo "***************************************************************"
echo "$(tput sgr0)"
