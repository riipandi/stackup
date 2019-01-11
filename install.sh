#!/bin/bash

PWD=$(dirname "$(readlink -f "$0")")

if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

