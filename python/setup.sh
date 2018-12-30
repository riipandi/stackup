#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

apt -y install {python,python3}-{dev,virtualenv,pip,setuptools,gunicorn,mysqldb} \
supervisor python-{m2crypto,configparser} gunicorn gunicorn3

source $ROOT/python/configure.sh 3.5
