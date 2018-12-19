# Another LEMP Stack Installer.

The LEMP software stack is a group of software that can be used to
serve dynamic web pages and web applications. This is an acronym
that describes a Linux operating system, with an Nginx web server.
The backend data is stored in the MySQL/MariaDB database and or
PostgreSQL as optional, and the dynamic processing is handled by
PHP and or Python.

## Prerequisites

- Fresh installed Debian 9 server with a root user.
- Domain with already pointed IP address to that server.

## Usage

Just run this command and follow the wizard:

```bash
bash <(wget -qO- raw.githubusercontent.com/riipandi/lempstack/master/setup.sh)
```

## Commands

### Create MySQL Database

```bash
export dbname="xxxxxxxxxxxxx"  # <-- change this variable
export dbuser="xxxxxxxxxxxxx"  # <-- change this variable
export dbpass="`pwgen -1 12`"  # <-- keep this variable

mysql -uroot -e "CREATE DATABASE IF NOT EXISTS $dbname"
mysql -uroot -e "CREATE USER IF NOT EXISTS '$dbuser'@'127.0.0.1' IDENTIFIED BY '$dbpass'"
mysql -uroot -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'127.0.0.1'; FLUSH PRIVILEGES"
```

### Create Nginx vHost

```bash
# Create virtualhost
vhost-create domain.tld

# Set Permission File dan Folder
fix-permission /srv/domain.tld www-data:

# Generet SSL Certificate
systemctl stop nginx
certbot certonly --standalone --rsa-key-size 4096 \
  --agree-tos --register-unsafely-without-email \
  -d domain.tld -d www.domain.tld

# Revoke SSL Certificate
certbot revoke --cert-path /etc/letsencrypt/live/domain.tld/fullchain.pem
```

## License

This project is open-sourced software licensed under the
[MIT license](https://opensource.org/licenses/MIT).
