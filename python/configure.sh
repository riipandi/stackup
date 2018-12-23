#!/usr/bin/env bash

default="3.5"

arr_ver=( '2.7' '3.5' )

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

# Get user parameter
if [[ ! -z $1 ]]; then default=$1 ; fi

if [[ "${arr_ver[*]}" != *"$default"* ]]; then
    echo -e "\nThat Python version doesnt' exist...\n"
    exit 1
fi

echo -e "\nConfiguring Python..."
echo
update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1 >/dev/null 2>&1
update-alternatives --install /usr/bin/python python /usr/bin/python3.5 2 >/dev/null 2>&1
update-alternatives --set python /usr/bin/python$default >/dev/null 2>&1

echo -e "$(python --version) is default now.\n"
