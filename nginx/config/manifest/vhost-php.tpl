server {
    listen 80;
    listen 443 ssl http2;
    server_name HOSTNAME www.HOSTNAME;

    root /srv/HOSTNAME/public;
    access_log /var/log/nginx/HOSTNAME-access.log main;
    error_log  /var/log/nginx/HOSTNAME-error.log warn;

    ssl_certificate      /etc/letsencrypt/live/HOSTNAME/fullchain.pem;
    ssl_certificate_key  /etc/letsencrypt/live/HOSTNAME/privkey.pem;
    #add_header Public-Key-Pins 'pin-sha256="HPKP_VALUE"; max-age=2592000;';

    # redirect to non-www
    if ($host = 'www.HOSTNAME') {
        return 301 https://HOSTNAME$request_uri;
    }

    # Hotlinking Protection
    location ~ .(gif|png|jpe?g)$ {
        valid_referers none blocked ~.google. ~.bing. ~.yahoo HOSTNAME *.HOSTNAME;
        if ($invalid_referer) { return 403; }
    }

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

