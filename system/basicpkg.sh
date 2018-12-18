#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

GetBin() {
    curl -L# $1 -o $2
    chmod a+x $2
}

apt update && apt full-upgrade -yqq

apt install -yqq sudo nano figlet elinks pwgen curl crudini lsof ntp \
ntpdate whois perl dirmngr software-properties-common debconf-utils \
apt-transport-https gcc make cmake build-essential binutils dnsutils \
nscd dh-autoreconf ftp zip unzip bsdtar pv rsync screen screenfetch \
ca-certificates resolvconf

apt autoremove -y

echo -e "\nDownloading extra utilities...\n"
GetBin https://semut.org/gdrive /usr/bin/gdrive
GetBin https://dl.eff.org/certbot-auto /usr/bin/certbot
GetBin https://git.io/vN3Ff /usr/bin/wp
GetBin https://git.io/fAFyN /usr/bin/phpcs
GetBin https://git.io/fAFyb /usr/bin/phpcbf
GetBin https://cs.sensiolabs.org/download/php-cs-fixer-v2.phar /usr/bin/php-cs-fixer
