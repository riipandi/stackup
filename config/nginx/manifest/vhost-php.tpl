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

    include server.d/server.conf;
    include server.d/static.conf;

    # php-fpm handler
    location / { try_files $uri $uri/ @rewrite; }
    location @rewrite { rewrite ^/(.*)$ /index.php?q=$1; }

    location ~ \.php(/|$) {
        fastcgi_pass unix:/var/run/php/php72-fpm.sock;
        include server.d/phpfpm.conf;
    }
}

