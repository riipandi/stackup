server {
    listen 80;
    server_name HOSTNAME;
    root /srv/HOSTNAME/public;
    include server.d/wpmu.conf;
}

#-server {
#-    listen 443 ssl http2;
#-
#-    server_name HOSTNAME *.HOSTNAME;
#-    root /srv/HOSTNAME/public;
#-    include server.d/wpmu.conf;
#-
#-    ssl_certificate         /etc/letsencrypt/live/HOSTNAME/fullchain.pem;
#-    ssl_certificate_key     /etc/letsencrypt/live/HOSTNAME/privkey.pem;
#-    ssl_trusted_certificate /etc/ssl/certs/chain.pem;
#-}
