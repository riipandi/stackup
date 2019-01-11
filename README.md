# Another LEMP Stack Installer.

The LEMP software stack is a group of software that can be used to
serve dynamic web pages and web applications. This is an acronym
that describes a Linux operating system, with an Nginx web server.
The backend data is stored in the MySQL/MariaDB database and or
PostgreSQL as optional, and the dynamic processing is handled by
PHP and or Python.

## Prerequisites

- Fresh installation of Ubuntu 16.04 or 18.04 LTS.
- Domain with already pointed IP address to that server.

If you prefer to use Debian, you can check [`debian`](//github.com/riipandi/lempstack/tree/debian) branch.

## Quick Start

Run this command as root and follow the wizard:

```sh
bash <(wget -qO- https://raw.githubusercontent.com/riipandi/lempstack/master/setup.sh)
```

## Some Useful Snippets

Command            | Description                                       | Example Usage
:------------------|:--------------------------------------------------|:-------------
set-php            | Set default PHP version                           | `sudo set-php 7.2`
set-python         | Set default Python version                        | `sudo set-python 3.5`
vhost-create       | Create Nginx VirtualHost for PHP-FPM backend      | `sudo vhost-create domain.tld`
vhost-python       | Create Nginx VirtualHost for Python backend       | `sudo vhost-python domain.tld`
fix-permission     | Fix directory and file permission                 | `sudo fix-permission /my/path user:group`
ssl-create         | Generate Let's Encrypt SSL certificate            | `sudo ssl-create domain.tld`
ssl-wildcard       | Generate wildcard Let's Encrypt SSL certificate   | `sudo ssl-wildcard domain.tld`
ssl-revoke         | Revoke Let's Encrypt SSL certificate              | `sudo ssl-revoke domain.tld`
mysql-create       | Create new MySQL database                         | `sudo mysql-create mydatabase`
mysql-drop         | Drop MySQL database and user                      | Run with sudo and follow the wizard
create-sudoer      | Create new user with sudo privileges              | Run with sudo and follow the wizard
create-buddy       | Create new user for act as deployer bot           | Run with sudo and follow the wizard

## License

This project is open-sourced software licensed under the [MIT license](./LICENSE).
