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

If you prefer to use Debian, you can check [`debian`](./tree/debian) branch.

## Quick Start

Run this command and follow the wizard:

```sh
bash <(wget -qO- raw.githubusercontent.com/riipandi/lempstack/master/setup.sh)
```

## Some Useful Snippets

Command            | Description                                       | Example Usage
:------------------|:--------------------------------------------------|:-------------
mysql-create       | Create new MySQL database                         | `sudo mysql-create mydatabase`
mysql-drop         | Drop MySQL database and user                      | Run with sudo and follow the wizard
vhost-create       | Create Nginx VirtualHost for PHP-FPM backend      | `sudo vhost-create domain.tld`
vhost-proxy        | Create Nginx VirtualHost for reverse proxy        | `sudo vhost-proxy domain.tld`
fix-permission     | Fix directory and file permission                 | `sudo fix-permission /my/path user:group`
ssl-create         | Generate Let's Encrypt SSL certificate            | `sudo ssl-create domain.tld`
ssl-wildcard       | Generate wildcard Let's Encrypt SSL certificate   | `sudo ssl-wildcard domain.tld`
ssl-revoke         | Revoke Let's Encrypt SSL certificate              | `sudo ssl-revoke domain.tld`
set-php            | Set default PHP version                           | `sudo set-php 7.2`
set-python         | Set default Python version                        | `sudo set-python 3.5`

## License

This project is open-sourced software licensed under the [MIT license](./LICENSE).
