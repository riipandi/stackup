#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PARENT=$(dirname `dirname $(readlink -f $0)`) || PARENT=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

# Linux SWAP
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Configuring Linux SWAP...${NC}"
swap_size=`crudini --get $PARENT/config/stackup.ini system swap_size`

if [[ $(cat /etc/fstab | grep -c "swapfile") -eq 0 ]]; then
    echo "/swapfile  none  swap  sw  0 0" >> /etc/fstab
    dd if=/dev/zero of=/swapfile count=$swap_size bs=1M
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    swapon --show
else
    echo -e "\nSwapfile already configured!\n"
fi
