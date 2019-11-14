#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

# Determine root directory
[ -z $ROOTDIR ] && PWD=$(dirname `dirname $(dirname $(readlink -f $0))`) || PWD=$ROOTDIR

# Common global variables
source "$PWD/common.sh"

# Determine os codename
osver=`echo ${osVersion} | tr '[:upper:]' '[:lower:]'`

#-----------------------------------------------------------------------------------------
msgSuccess "\n--- Upgrade system and install core packages"
#-----------------------------------------------------------------------------------------
if   [ $checkCountry == "ID" ] ; then REPOFILE="$PWD/config/repo/ubuntu-id.list"
elif [ $checkCountry == "SG" ] ; then REPOFILE="$PWD/config/repo/ubuntu-sg.list"
elif [ $checkCountry == "US" ] ; then REPOFILE="$PWD/config/repo/ubuntu-us.list"
else REPOFILE="$PWD/config/repo/ubuntu-xx.list" ; fi

cat "${REPOFILE}" > /etc/apt/sources.list
sed -i "s/CODENAME/$(lsb_release -cs)/" /etc/apt/sources.list
rm -fr /etc/apt/sources.list.d/*

# -mmin -360 finds files that have a change time in the last 6 hours.
# You can use -mtime if you care about longer times (days).
if [ -z "$(find -H /var/lib/apt/lists -maxdepth 0 -mtime -60)" ]; then
    msgInfo "\nUpdating base system packages..."
    pkgUpgrade
else
    apt update -yqq &>/dev/null
fi

# Install core packages
#-----------------------------------------------------------------------------------------
msgInfo "Installing essential packages.."
apt -yqq install screen elinks lsof dirmngr gnupg debconf-utils build-essential gcc make \
cmake whois rsync dh-autoreconf screenfetch jpegoptim optipng apache2-utils sshpass xsel \
pv libpq-dev python3 python3-dev python3-wheel python3-pip python3-setuptools python3-venv \
python3-virtualenv python3-psycopg2 virtualenv ansible &>/dev/null
