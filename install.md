## Dependencies

```
apt update
apt -y install python3-venv python3-{click,dev,pip,setuptools,gunicorn,virtualenv} gunicorn3

update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1 >/dev/null 2>&1
update-alternatives --install /usr/bin/python python /usr/bin/python3.6 2 >/dev/null 2>&1
update-alternatives --set python /usr/bin/python3.6 >/dev/null 2>&1 && python -V

sudo pip install pipenv
```

## Install Web Interface

```
cd /opt/elsacp/web
python -m venv venv
source venv/bin/activate
venv/bin/pip3 install -r requirements.txt
```

## Systemd Daemon

```
touch /etc/systemd/system/elsacp.service
chmod 0755 /etc/systemd/system/elsacp.service
cat > /etc/systemd/system/elsacp.service <<EOF
[Unit]
Description = ElsaCP Daemon
After = network.target

[Service]
PermissionsStartOnly = true
PIDFile = /var/run/elsacp/elsacp.pid
WorkingDirectory = /opt/elsacp/web
ExecStartPre = /bin/mkdir -p /var/run/elsacp /var/log/elsacp
ExecStartPre = /bin/chown -R webmaster:webmaster /var/run/elsacp /var/log/elsacp
ExecStart = /opt/elsacp/web/venv/bin/gunicorn -c /opt/elsacp/web/gunicorn.py main:app
;ExecStart = /usr/local/bin/pipenv run gunicorn -c /opt/elsacp/web/gunicorn.py main:app
ExecReload = /bin/kill -s HUP $MAINPID
ExecStop = /bin/kill -s TERM $MAINPID
ExecStopPost = /bin/rm -rf /var/run/elsacp
PrivateTmp = true

[Install]
WantedBy = multi-user.target
EOF
```

```
systemctl daemon-reload
systemctl enable elsacp
systemctl restart elsacp
systemctl status elsacp
netstat -pltn | grep 2080

tail -f /var/log/elsacp/error.log
```
