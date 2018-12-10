#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

# Get Country Code
curl -s ipinfo.io | grep country | awk -F":" '{print $2}' | cut -d '"' -f2 > /tmp/country

country=`cat /tmp/country`

if [ "$country" == "ID" ] ; then
  echo "deb http://kebo.pens.ac.id/debian `lsb_release -cs` main contrib non-free" > /etc/apt/sources.list
  echo "deb http://kebo.pens.ac.id/debian `lsb_release -cs`-updates main contrib non-free" >> /etc/apt/sources.list
elif [ "$country" == "SG" ] ; then
  echo "deb http://ftp.sg.debian.org/debian `lsb_release -cs` main contrib non-free" > /etc/apt/sources.list
  echo "deb http://ftp.sg.debian.org/debian `lsb_release -cs`-updates main contrib non-free" >> /etc/apt/sources.list
else
  echo "deb http://mirror.0x.sg/debian `lsb_release -cs` main contrib non-free" > /etc/apt/sources.list
  echo "deb http://mirror.0x.sg/debian `lsb_release -cs`-updates main contrib non-free" >> /etc/apt/sources.list
fi
echo "deb http://debian-archive.trafficmanager.net/debian-security `lsb_release -cs`/updates main contrib non-free" >> /etc/apt/sources.list

echo "Repository has been configured"
