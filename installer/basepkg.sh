#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi


# Install basic packages.
apt update ; apt -qy install sudo nano figlet elinks pwgen curl crudini lsof ntp \
ntpdate perl dirmngr software-properties-common debconf-utils apt-transport-https \
gcc make cmake build-essential whois nscd binutils dnsutils dh-autoreconf ftp zip \
unzip bsdtar rsync screen screenfetch ca-certificates resolvconf

curl -L# https://semut.org/gdrive -o /usr/bin/gdrive ; chmod a+x /usr/bin/gdrive
