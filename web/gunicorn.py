#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import gunicorn
import multiprocessing

gunicorn.SERVER_SOFTWARE = 'nginx'

bind = '0.0.0.0:2080'

loglevel = 'warning'
pid = '/var/run/elsacp/elsacp.pid'
errorlog = '/var/log/elsacp/error.log'
accesslog = '/var/log/elsacp/access.log'
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s"'

daemon = False
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = 'sync'
worker_connections = 1000
threads = 2
timeout = 30
keepalive = 2

keyfile = '/etc/letsencrypt/live/org-a.aris.web.id/privkey.pem'
certfile = '/etc/letsencrypt/live/org-a.aris.web.id/fullchain.pem'
ca_certs = '/etc/ssl/certs/chain.pem'
