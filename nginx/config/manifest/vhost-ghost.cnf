#-server {
#-    listen 80; server_name HOSTNAME;
#-    return 301 https://$host$request_uri;
#-    access_log off; error_log off;
#-}

server {
    listen 80;
    listen 443 ssl http2;
    server_name HOSTNAME;

    root /srv/HOSTNAME/public;
    access_log /var/log/nginx/HOSTNAME-access.log main;
    error_log  /var/log/nginx/HOSTNAME-error.log warn;

    ssl_certificate      /etc/letsencrypt/live/HOSTNAME/fullchain.pem;
    ssl_certificate_key  /etc/letsencrypt/live/HOSTNAME/privkey.pem;
    #add_header Public-Key-Pins 'pin-sha256="HPKP_VALUE"; max-age=2592000;';

    # Ghost Handler
    include server.d/server.conf;
    location / {
        proxy_buffering  off;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header User-Agent $http_user_agent;
        proxy_set_header Host $http_host;
        proxy_pass http://127.0.0.1:GHOST_PORT;
    }
}