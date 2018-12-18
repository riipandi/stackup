#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

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
apt -y autoremove
apt clean

echo "Repository has been configured"
