#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PWD=$(dirname `dirname $(readlink -f $0)`) || PWD=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

echo -e "\n${OK}Installing pgAdmin4...${NC}"

[[ ! -d /var/www ]] && mkdir -p /var/www
[[ ! -d /var/www/pgadmin ]] || rm -fr /var/www/pgadmin

apt update ; apt -y install pgadmin4 python3-flask python3-flask-babelex uwsgi-plugin-python3 libgmp3-dev libpq-dev

mkdir -p /var/cache/pgadmin/sessions
chown -R www-data: /usr/share/pgadmin4
chown -R www-data: /var/cache/pgadmin
python3 /usr/share/pgadmin4/web/setup.py

# Nginx vhost
mv /etc/nginx/conf.d/pgadmin.{conf-disable,conf}
sed -i "s/HOSTNAME/$(hostname -f)/" /etc/nginx/conf.d/pgadmin.conf
systemctl restart nginx

cat > /etc/supervisor/conf.d/pgadmin4.conf <<EOF
[program:pgadmin4]
directory=/usr/share/pgadmin4/web
command=/usr/bin/python3 /usr/share/pgadmin4/web/pgAdmin4.py
stderr_logfile=/var/log/supervisor/pgadmin4-err.log
stdout_logfile=/var/log/supervisor/pgadmin4-out.log
autorestart=true
autostart=true
user=root
EOF
supervisorctl reread
supervisorctl update
systemctl restart supervisor
netstat -pltn | grep 5050
tail -f /var/log/supervisor/pgadmin4-err.log
