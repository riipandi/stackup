#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

GetBin(){
    curl -L# $1 -o $2
    chmod a+x $2
}

# country=`cat /tmp/country`
# if [ "$country" == "ID" ] ; then
#   echo "deb http://kebo.pens.ac.id/debian `lsb_release -cs` main contrib non-free" > /etc/apt/sources.list
#   echo "deb http://kebo.pens.ac.id/debian `lsb_release -cs`-updates main contrib non-free" >> /etc/apt/sources.list
# elif [ "$country" == "SG" ] ; then
#   echo "deb http://ftp.sg.debian.org/debian `lsb_release -cs` main contrib non-free" > /etc/apt/sources.list
#   echo "deb http://ftp.sg.debian.org/debian `lsb_release -cs`-updates main contrib non-free" >> /etc/apt/sources.list
# else
#   echo "deb http://mirror.0x.sg/debian `lsb_release -cs` main contrib non-free" > /etc/apt/sources.list
#   echo "deb http://mirror.0x.sg/debian `lsb_release -cs`-updates main contrib non-free" >> /etc/apt/sources.list
# fi
# echo "deb http://debian-archive.trafficmanager.net/debian-security `lsb_release -cs`/updates main contrib non-free" >> /etc/apt/sources.list

cat > /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian stable main contrib non-free
deb http://deb.debian.org/debian stable-updates main contrib non-free
deb http://deb.debian.org/debian-security stable/updates main contrib non-free
EOF

apt update
apt -y full-upgrade

apt -yqq install sudo nano figlet elinks pwgen curl crudini lsof ntp \
ntpdate whois perl dirmngr software-properties-common debconf-utils \
apt-transport-https gcc make cmake build-essential binutils dnsutils \
nscd dh-autoreconf ftp zip unzip bsdtar rsync screen screenfetch \
ca-certificates resolvconf

apt -y autoremove

# Extra Packages
GetBin https://semut.org/gdrive /usr/bin/gdrive
GetBin https://dl.eff.org/certbot-auto /usr/bin/certbot
GetBin https://git.io/vN3Ff /usr/bin/wp
GetBin https://git.io/fAFyN /usr/bin/phpcs
GetBin https://git.io/fAFyb /usr/bin/phpcbf
GetBin https://cs.sensiolabs.org/download/php-cs-fixer-v2.phar /usr/bin/php-cs-fixer
