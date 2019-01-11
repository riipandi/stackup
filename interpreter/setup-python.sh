#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

PWD=$(dirname "$(readlink -f "$0")")
PARENT=$(dirname "$PWD")

apt -y install {python,python3}-{dev,pip,setuptools,gunicorn,mysqldb} python-pip-whl \
libpython2.7 python-{m2crypto,configparser} {python2.7,libpython,libpython2.7}-dev \
gunicorn gunicorn3 supervisor

wget https://raw.githubusercontent.com/chenull/py3crudini/master/crudini -qO /usr/bin/crudini

bash $PARENT/snippets/set-python 3.5
