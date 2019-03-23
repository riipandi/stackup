# Linux Stack Made Easy.

The LEMP / LAMP software stack is a group of software that can be used
to serve dynamic web pages and web applications. This is an acronym
that describes a Linux operating system, with an Nginx or Apache web
server. The backend data is stored in the MySQL/MariaDB database and
or PostgreSQL as optional, and the dynamic processing is handled by
PHP, Python, Nodejs, etc.

## Prerequisites

- Fresh installation of Ubuntu 16.04 or 18.04 LTS.
- Domain with already pointed IP address to your server.

If you prefer to use Debian, you can check [`debian`](//github.com/riipandi/stackup/tree/debian) branch.

## Quick Start

Run this command as root and follow the wizard:

```sh
# Stable channel
bash <(curl -sLo- https://git.io/fhiA7 || wget -qO- https://git.io/fhiA7)

# Master branch
bash <(curl -sLo- https://git.io/fhiA7 || wget -qO- https://git.io/fhiA7) --dev
```

## Manual Installation

If you prefer to run installation manually, you can follow this step:

1. Clone this repo or download latest release from [release page](//github.com/riipandi/stackup/releases/latest).
2. Extract downloaded file and make all `*.sh` and `snippets` files executable.
3. Install basic dependencies: `apt -y install sudo git curl crudini openssl figlet perl`
4. Start installation process by executing `install.sh` file.
5. Follow the installation wizard as usual.

You can also configure the `config.ini` file manually if you don't want to use the installation wizard.

Change `ready=no` to `ready=yes` in `config.ini` file, then execute `install.sh` file.

## Some Useful Snippets

| Command             | Description                                         | Example Usage
| :------------------ | :-------------------------------------------------- | :------------
| create-sudoer       | Create new user with sudo privileges                | _Run with sudo privileges_
| set-default-php     | Set default PHP version                             | `sudo set-php 7.2`
| set-default-python  | Set default Python version                          | `sudo set-python 3.5`
| site-ghost          | Create or uninstall Ghost blogging platform         | `site-ghost example.com`
| ------------------- | --------------------------------------------------- | `site-ghost example.com --uninstall`
| site-php            | Create Nginx virtualhost for php-fpm backend        | `sudo site-php example.com`
| site-proxy          | Create Nginx virtualhost for reverse proxy          | `sudo site-proxy example.com`
| site-python         | Create Nginx virtualhost for python backend         | `sudo site-python example.com`
| fix-permission      | Fix directory and file permission                   | `sudo fix-permission /my/path user:group`
| mysql-create        | Create new MySQL database                           | `sudo mysql-create mydatabase`
| mysql-drop          | Drop MySQL database and user                        | `sudo mysql-drop`
| mysql-list          | List MySQL databases and users                      | `sudo mysql-list`
| ssl-create          | Generate Let's Encrypt SSL certificate              | `sudo ssl-create example.com`
| ssl-revoke          | Revoke Let's Encrypt SSL certificate                | `sudo ssl-revoke example.com`
| ssl-wildcard        | Generate wildcard Let's Encrypt SSL certificate     | `sudo ssl-wildcard example.com`

## TODO List

- [x] Change license from MIT to Apache 2.0
- [x] Write the change logs
- [ ] Make each setup script as independent installer
- [ ] Add more snippets

## License

Copyright (c) 2018-2019 Aris Ripandi

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at: <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

---

## Changelog

All notable changes to this project will be documented here, the changelog 
format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

### [Unreleased]

### [2.3] - 2019/01/29
- Added Adminer as optional DB GUI
- Move phpMyAdmin to an alias
- Some configuration fixes

### [2.2] - 2019/01/13
- Add default user administartor
- Add feature for creating Ghost blogging platform
- Fix setup develoment environment
- Fix some nginx configuration
- Small fixes for some snippets
- Fix character encoding

### [2.1] - 2019/01/12
- Add development channel
- Fix default web page
- Fix default php page
- Fix some nginx configuration
- Some minor fixes and typo

### [2.0] - 2019/01/12
- Switch to Ubuntu LTS
- Nginx installer
- PHP FPM installer
- Python installer
- PostgreSQL installer
- MariaDB installer
- MySQL installer
- SSL Cert snippet
- MySQL snippet
- VirtualHost snippet
- Select databse version to install

### [1.0] - 2018/12/30
- Initial Release
- Nginx installer
- PHP FPM installer
- Python installer
- MariaDB installer
- VirtualHost snippet
- SSL Cert snippet
- MySQL snippet
