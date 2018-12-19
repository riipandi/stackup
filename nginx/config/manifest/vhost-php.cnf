server {
    listen 80;
    listen 443 ssl http2;
    server_name HOSTNAME www.HOSTNAME;

    root /srv/HOSTNAME/public;
    access_log /var/log/nginx/HOSTNAME-access.log main;
    error_log  /var/log/nginx/HOSTNAME-error.log warn;

    ssl_certificate      /etc/letsencrypt/live/HOSTNAME/fullchain.pem;
    ssl_certificate_key  /etc/letsencrypt/live/HOSTNAME/privkey.pem;

    # enabling Public Key Pinning Extension for HTTP (HPKP)
    # https://developer.mozilla.org/en-US/docs/Web/Security/Public_Key_Pinning
    # to generate use on of these:
    # $ openssl rsa -in my-website.key -outform der -pubout | openssl dgst -sha256 -binary | base64
    # $ openssl req -in my-website.csr -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | base64
    # $ openssl x509 -in my-website.crt -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | base64
    # add_header Public-Key-Pins 'pin-sha256="base64+info1="; max-age=31536000; includeSubDomains';
    # add_header Public-Key-Pins 'pin-sha256="HPKP_VALUE"; max-age=7890000;';

    # redirect to non-www
    if ($host = 'www.HOSTNAME') {
        return 301 https://HOSTNAME$request_uri;
    }

    # Hotlinking Protection
    location ~ .(gif|png|jpe?g)$ {
        valid_referers none blocked ~.google. ~.bing. ~.yahoo HOSTNAME *.HOSTNAME;
        if ($invalid_referer) { return 403; }
    }

    include server.d/errors.conf;
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
