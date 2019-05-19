#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOT ] && PWD=$(dirname `dirname $(readlink -f $0)`) || PWD=$ROOT
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

echo -e "\n${OK}Installing pgAdmin4...${NC}"

[[ ! -d /var/www ]] && mkdir -p /var/www
[[ ! -d /var/www/pgadmin ]] || rm -fr /var/www/pgadmin

apt update ; apt -y full-upgrade
apt -y install pgadmin4 python3-flask python3-flask-babelex uwsgi-plugin-python3 libgmp3-dev libpq-dev

mkdir -p /var/cache/pgadmin/sessions
chown -R webmaster: /usr/share/pgadmin4
chown -R webmaster: /var/cache/pgadmin
python3 /usr/share/pgadmin4/web/setup.py

# Systemd service
touch /etc/systemd/system/pgadmin.service
chmod 0755 /etc/systemd/system/pgadmin.service
cat > /etc/systemd/system/pgadmin.service <<EOF
[Unit]
Description = pgadmin Daemon
After = network.target

[Service]
PermissionsStartOnly = true
WorkingDirectory = /usr/share/pgadmin4/web
ExecStart = /usr/bin/python3 /usr/share/pgadmin4/web/pgAdmin4.py
ExecReload = /bin/kill -s HUP $MAINPID
ExecStop = /bin/kill -s TERM $MAINPID
PrivateTmp = true

[Install]
WantedBy = multi-user.target
EOF
systemctl daemon-reload
systemctl enable pgadmin

systemctl restart pgadmin
systemctl status pgadmin
