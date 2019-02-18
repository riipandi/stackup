# Linux Stack Made Easy.

The LEMP / LAMP software stack is a group of software that can be used 
to serve dynamic web pages and web applications. This is an acronym
that describes a Linux operating system, with an Nginx or Apache web 
server. The backend data is stored in the MySQL/MariaDB database and 
or PostgreSQL as optional, and the dynamic processing is handled by
PHP and or Python.

## Prerequisites

- Fresh installation of Ubuntu 16.04 or 18.04 LTS.
- Domain with already pointed IP address to that server.

If you prefer to use Debian, you can check [`debian`](//github.com/riipandi/lempstack/tree/debian) branch.

## Quick Start

Run this command as root and follow the wizard:

```sh
# Stable channel
bash <(wget -qO- https://raw.githubusercontent.com/riipandi/lempstack/master/setup.sh)

# Master branch
bash <(wget -qO- https://raw.githubusercontent.com/riipandi/lempstack/master/setup.sh) --dev
```

## Manual Installation

If you prefer to run installation manually, you can follow this step:

1. Clone this repo or download latest release from [release page](//github.com/riipandi/lempstack/releases/latest).
2. Extract downloaded file and make all `*.sh` and `snippets` files executable.
3. Install basic dependencies: `apt -y install sudo git curl crudini openssl figlet perl`
4. Start installation process by executing `install.sh` file.
5. Follow the installation wizard as usual.

You can also configure the `config.ini` file manually if you don't want to use the installation wizard.

Change `ready=no` to `ready=yes` in `config.ini` file, then execute `install.sh` file.

## Some Useful Snippets

Command            | Description                                       | Example Usage
:------------------|:--------------------------------------------------|:-------------
set-php            | Set default PHP version                           | `sudo set-php 7.2`
set-python         | Set default Python version                        | `sudo set-python 3.5`
vhost-create       | Create Nginx VirtualHost for PHP-FPM backend      | `sudo vhost-create domain.tld`
vhost-python       | Create Nginx VirtualHost for Python backend       | `sudo vhost-python domain.tld`
vhost-ghost        | Create or uninstall Ghost blogging platform       | `sudo vhost-ghost domain.tld`
-------------------|---------------------------------------------------| `sudo vhost-ghost domain.tld --uninstall`
fix-permission     | Fix directory and file permission                 | `sudo fix-permission /my/path user:group`
ssl-create         | Generate Let's Encrypt SSL certificate            | `sudo ssl-create domain.tld`
ssl-wildcard       | Generate wildcard Let's Encrypt SSL certificate   | `sudo ssl-wildcard domain.tld`
ssl-revoke         | Revoke Let's Encrypt SSL certificate              | `sudo ssl-revoke domain.tld`
mysql-create       | Create new MySQL database                         | `sudo mysql-create mydatabase`
mysql-drop         | Drop MySQL database and user                      |  |
create-sudoer      | Create new user with sudo privileges              | Run with sudo and follow the wizard
create-buddy       | Create new user for act as deployer bot           |  |

## License

This project is open-sourced software licensed under the [MIT license](./LICENSE).
