#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

[ -z $ROOT ] && PARENT=$(dirname "$(readlink -f "$0")") || PARENT=$ROOT

DEFAULT_PYTHON=`crudini --get $PARENT/config.ini python default`

apt install -y {python,python3}-{dev,pip,setuptools,gunicorn,mysqldb} python-pip-whl \
python-{m2crypto,configparser} gunicorn gunicorn3 supervisor

# crudini for Python3
wget https://raw.githubusercontent.com/chenull/py3crudini/master/crudini -qO /usr/bin/crudini3

bash $PARENT/snippets/set-python $DEFAULT_PYTHON
