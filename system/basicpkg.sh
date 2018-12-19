#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

echo -e "\nUpdating packages..."
apt update -qq

echo -e "\nUpgrading packages..."
apt full-upgrade -yqq

echo -e "\nInstalling basic packages..."
apt install -yqq sudo nano figlet elinks pwgen curl crudini lsof ntp \
ntpdate whois perl dirmngr software-properties-common debconf-utils \
apt-transport-https gcc make cmake build-essential binutils dnsutils \
nscd dh-autoreconf ftp zip unzip bsdtar pv rsync screen screenfetch \
ca-certificates resolvconf

echo -e "\nRemoving unnecessary packages..."
apt autoremove -y

echo -e "\nDownloading extra utilities..."

curl -L# "https://dl.eff.org/certbot-auto" -o /usr/local/bin/certbot
curl -L# "https://git.io/vN3Ff" -o /usr/local/bin/wp
curl -L# "https://git.io/fAFyN" -o /usr/local/bin/phpcs
curl -L# "https://git.io/fAFyb" -o /usr/local/bin/phpcbf
curl -L# "https://cs.sensiolabs.org/download/php-cs-fixer-v2.phar" -o /usr/local/bin/php-cs-fixer
curl -L# "https://docs.google.com/uc?id=0B3X9GlR6EmbnQ0FtZmJJUXEyRTA&export=download" -o /usr/local/bin/gdrive

echo -e "\nDownloading Diffie-Hellman Parameter..."

curl -L# https://2ton.com.au/dhparam/4096/ssh -o /etc/ssh/moduli
curl -L# https://2ton.com.au/dhparam/2048 -o /etc/ssl/certs/dhparam-2048.pem
curl -L# https://2ton.com.au/dhparam/3072 -o /etc/ssl/certs/dhparam-3072.pem
curl -L# https://2ton.com.au/dhparam/4096 -o /etc/ssl/certs/dhparam-4096.pem
