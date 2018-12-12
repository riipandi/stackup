#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi


apt -y install {python,python3}-{dev,virtualenv,pip,setuptools,gunicorn,mysqldb} \
supervisor {python,python3}-{flaskext.wtf,flask-{migrate,restful,sqlalchemy,bcrypt}} \
python-{m2crypto,configparser} gunicorn gunicorn3