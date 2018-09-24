server {
    listen 80;
    server_name ~^(?<user>[a-zA-Z0-9-]+)\.domain\.com$;
    root /srv/HOSTNAME/public;
    include server.d/wpmu.conf;
    # return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;

    server_name HOSTNAME *.HOSTNAME;
    root /srv/HOSTNAME/public;
    include server.d/wpmu.conf;

    ssl_certificate         /etc/letsencrypt/live/HOSTNAME/fullchain.pem;
    ssl_certificate_key     /etc/letsencrypt/live/HOSTNAME/privkey.pem;
    ssl_trusted_certificate /etc/ssl/certs/chain.pem;
    # add_header Public-Key-Pins 'pin-sha256="HPKP_VALUE"; max-age=2592000;';
}


server {
    listen 80; listen 443 ssl http2;
    server_name www.HOSTNAME;
    return 301 https://HOSTNAME$request_uri;
    access_log off; error_log off;
    ssl_certificate         /etc/letsencrypt/live/HOSTNAME/fullchain.pem;
    ssl_certificate_key     /etc/letsencrypt/live/HOSTNAME/privkey.pem;
    ssl_trusted_certificate /etc/ssl/certs/chain.pem;
}
