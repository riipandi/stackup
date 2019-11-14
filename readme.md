# Linux Stack Made Easy.

The LEMP / LAMP software stack is a group of software that can be used to serve dynamic web pages
and web applications. This is an acronym that describes a Linux operating system with an Nginx or
Apache web server. The backend data is stored in the database engine such as MySQL or MariaDB and
or PostgreSQL as optional, and the dynamic processing is handled by PHP, Python, Nodejs, etc.

## Prerequisites

- A machine with a minimum of 1GB RAM and 20GB of storage.
- Fresh installation of supported OS distribution.

### Supported Distribution

- Debian 9 (Stretch)
- Debian 10 (Buster)
- Ubuntu 16.04 (Xenial)
- Ubuntu 18.04 (Bionic)

## Quick Start

Run this command as root and follow the wizard:

```sh
# Stable channel
bash <(curl -sLo- git.io/fhiA7 || wget -qO- git.io/fhiA7)

# Master branch
bash <(curl -sLo- git.io/fhiA7 || wget -qO- git.io/fhiA7) --dev
```

If you prefer to run installation manually, you have clone this repo then run `setup.sh` as root.

After finish, installation information stored at: `/tmp/stackup-install.log`

### Installation notes in AWS

AWS Lightsail doesn't use password by default for ssh authentication. You will need to download
SSH key from Lightsail management console. Also, AWS Lightsail use generated hostname for you
instance, you must change your instance hostname.

```sh
ssh username@ip_address -i LightsailDefaultKey-zone.pem
```

### Port that needs to be opened

| Protocol  | Type  | Port
| :---------| :-----| :---
| HTTP      | tcp   | 80
| HTTPS     | tcp   | 443
| SSH       | tcp   | 22 (or, according to your configuration)
| FTP       | tcp   | 21 and 50000-50100

## License

Copyright (c) 2018-2019 Aris Ripandi

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
in compliance with the License. You may obtain a copy of the License at: <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software distributed under the License
is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
or implied. See the License for the specific language governing permissions and limitations under
the License.
