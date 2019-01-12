#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

[ -z $ROOT ] && PARENT=$(dirname "$(readlink -f "$0")") || PARENT=$ROOT

if [[ $(cat /etc/fstab | grep -c "swapfile") -eq 0 ]]; then
    echo "/swapfile  none  swap  sw  0 0" >> /etc/fstab
    size=`crudini --get $PARENT/config.ini system swap_size`
    dd if=/dev/zero of=/swapfile count=$size bs=1M
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    swapon --show
else
    echo -e "\nSwapfile already configured!\n"
fi
