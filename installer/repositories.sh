#!/bin/bash

PWD=$(dirname "$(readlink -f "$0")")
PARENT=$(dirname $PWD)

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

# Get Country Code
curl -s ipinfo.io | grep country | awk -F":" '{print $2}' | cut -d '"' -f2 > /tmp/country

country=`cat /tmp/country`

if [ "$country" == "ID" ] ; then
  echo "deb http://kebo.pens.ac.id/debian `lsb_release -cs` main contrib non-free" > /etc/apt/sources.list
  echo "deb http://kebo.pens.ac.id/debian `lsb_release -cs`-updates main contrib non-free" >> /etc/apt/sources.list
  echo "deb http://kebo.pens.ac.id/debian-security `lsb_release -cs`/updates main contrib non-free" >> /etc/apt/sources.list
elif [ "$country" == "SG" ] ; then
  echo "deb http://sgp1.mirrors.digitalocean.com/debian `lsb_release -cs` main contrib non-free" > /etc/apt/sources.list
  echo "deb http://sgp1.mirrors.digitalocean.com/debian `lsb_release -cs`-updates main contrib non-free" >> /etc/apt/sources.list
  echo "deb http://security.debian.org/debian-security `lsb_release -cs`/updates main contrib non-free" >> /etc/apt/sources.list
else
  echo "deb http://debian-archive.trafficmanager.net/debian `lsb_release -cs` main contrib non-free" > /etc/apt/sources.list
  echo "deb http://debian-archive.trafficmanager.net/debian `lsb_release -cs`-updates main contrib non-free" >> /etc/apt/sources.list
  echo "deb http://debian-archive.trafficmanager.net/debian-security `lsb_release -cs`/updates main contrib non-free" >> /etc/apt/sources.list
fi

echo 'Repository has been configured'
