# Another LEMP Stack installer script.

The LEMP software stack is a group of software that can be used to
serve dynamic web pages and web applications. This is an acronym
that describes a Linux operating system, with an Nginx web server.
The backend data is stored in the MySQL/MariaDB database and the
dynamic processing is handled by PHP and or Python.

## Prerequisites

You will need a fresh installed Debian 9 server with a root user.

## Usage

Just run this command and follow the wizard:

```bash
bash <(wget -qO- raw.githubusercontent.com/riipandi/lempstack/master/setup.sh)
```

## Commands

### Create MySQL Database

```bash
mysql -uroot -e "CREATE DATABASE IF NOT EXISTS dbname"
mysql -uroot -e "CREATE USER IF NOT EXISTS 'dbuser'@'127.0.0.1' IDENTIFIED BY 'dbpass'"
mysql -uroot -e "GRANT ALL PRIVILEGES ON dbname.* TO 'dbuser'@'127.0.0.1'; FLUSH PRIVILEGES"
```

### Create Nginx vHost

```bash
# Create Web directory
mkdir -p /srv/domain.tld/public
cp /etc/nginx/manifest/welcome.tpl /srv/domain.tld/public/index.php
chown -R www-data: /srv/domain.tld

# Virtual Host Configuration
cp /etc/nginx/manifest/vhost-php.tpl /etc/nginx/vhost.d/domain.tld.conf
sed -i "s/HOSTNAME/domain.tld/" /etc/nginx/vhost.d/domain.tld.conf

# Generet SSL Certificate
systemctl stop nginx ; certbot certonly --standalone --rsa-key-size 4096 \
 --agree-tos --register-unsafely-without-email -d domain.tld -d www.domain.tld

# Set Permission File dan Folder
cd /srv/domain.tld
find . -type d -exec chmod 0777 {} \;
find . -type f -exec chmod 0775 {} \;
find . -exec chown -R www-data: {} \;
```

## License

This project is open-sourced software licensed under the
[MIT license](https://opensource.org/licenses/MIT).
