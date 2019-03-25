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

If you prefer to run installation manually, you just clone this repo then run setup script in `installer` directory.

## Some Useful Snippets

| Command             | Description                                         | Example Usage
| :------------------ | :-------------------------------------------------- | :------------
| create-buddy        | Create new user for application deployment          | `sudo create-buddy`
| create-user         | Create new user with sudo privileges                | `sudo create-user`
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
- [x] Make each setup script as independent installer
- [ ] Fix pgAdmin4 installation
- [ ] Add automatic installation wizard
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
