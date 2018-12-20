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
# Using simple command:

sudo mysql-create

# Or, you can use manual method. Don't
# forget to adjust the variables value.

export dbname="xxxxxxxxxxxxx"  # <-- change this value
export dbuser="xxxxxxxxxxxxx"  # <-- change this value
export dbpass="`pwgen -1 16`"  # <-- keep this variable

mysql -uroot -e "CREATE DATABASE IF NOT EXISTS $dbname"
mysql -uroot -e "CREATE USER IF NOT EXISTS '$dbuser'@'127.0.0.1' IDENTIFIED BY '$dbpass'"
mysql -uroot -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'127.0.0.1'; FLUSH PRIVILEGES"
```

### Create Nginx vHost

```bash
# Create virtualhost
sudo vhost-create domain.tld

# Set Permission File dan Folder
sudo fix-permission /srv/domain.tld www-data:

# Generet SSL Certificate
sudo ssl-create domain.tld

# Generate Wildcard Certificate
sudo ssl-wildcard domain.tld

# Revoke Certificate
sudo ssl-revoke domain.tld
```

## License

This project is open-sourced software licensed under the
[MIT license](https://opensource.org/licenses/MIT).
