#!/usr/bin/env bash

ROOT=$(dirname "$(readlink -f "$0")")

# Check if this script running as root
if [[ $EUID -ne 0 ]]; then
    echo -e 'This script must be run as root'
    exit 1
else
    read -p "Press enter to continue ..."
fi

#-----------------------------------------------------------------------------------------
# Some functions
#-----------------------------------------------------------------------------------------

InstallPackage() {
    if [ `crudini --get $ROOT/config.ini $1 $2` == "yes" ]; then
        source $3
    fi
}

CountDown() (
    IFS=:
    set -- $*
    secs=$(( ${1#0} * 3600 + ${2#0} * 60 + ${3#0} ))
    while [ $secs -gt 0 ] ; do
        sleep 1 &
        printf "\r%02d:%02d:%02d" $((secs/3600)) $(( (secs/60)%60)) $((secs%60))
        secs=$(( $secs - 1 ))
        wait
    done
    echo
)

#-----------------------------------------------------------------------------------------
# Initial Setup
#-----------------------------------------------------------------------------------------
rm -f /etc/resolv.conf
echo 'nameserver 209.244.0.3' >  /etc/resolv.conf
echo 'nameserver 209.244.0.4' >> /etc/resolv.conf

if [[ `crudini --get $ROOT/config.ini setup ready` != "yes" ]] ; then
    source $ROOT/wizard.sh
fi

echo -e "" && read -p "Press enter to begin installation..."

#-----------------------------------------------------------------------------------------
# Server configuration and install packages
#-----------------------------------------------------------------------------------------
InstallPackage swap enable $ROOT/system/swap.sh
source $ROOT/system/netconfig.sh

InstallPackage php php56 $ROOT/php/setup56.sh
InstallPackage php php72 $ROOT/php/setup72.sh
InstallPackage php php73 $ROOT/php/setup73.sh
source $ROOT/php/configure.sh

source $ROOT/nginx/setup.sh
source $ROOT/nginx/phpmy.sh
InstallPackage nginx amplify $ROOT/nginx/amplify.sh

# Setup MySQL / MariaDB Database
if [[ `crudini --get $ROOT/config.ini mysql engine` == "mariadb" ]] ; then
    source $ROOT/mysql/mariadb.sh
    source $ROOT/mysql/configure.sh
else
    source $ROOT/mysql/mysql80.sh
fi

InstallPackage redis install $ROOT/redis/setup.sh
InstallPackage postgres install $ROOT/postgres/setup.sh
InstallPackage extras nodejs $ROOT/nodejs/setup.sh
InstallPackage extras python $ROOT/python/setup.sh

# InstallPackage powerdns install $ROOT/powerdns/setup.sh
InstallPackage mailserver install $ROOT/mailsuite/mailserver.sh
InstallPackage extras imapsync $ROOT/mailsuite/imapsync.sh

#-----------------------------------------------------------------------------------------
# Cleanup
#-----------------------------------------------------------------------------------------
cp $ROOT/python/configure.sh /usr/local/bin/
cp $ROOT/php/configure.sh /usr/local/bin/
cp $ROOT/snippets/* /usr/local/bin/

# Fix permission for snippets
chown -R root: /usr/local/bin/*
chmod a+x /usr/local/bin/*

echo "" && apt -y autoremove && apt clean && netstat -pltn

echo -e "\nCongratulation, server stack has been installed.\n"

if [[ `crudini --get $ROOT/config.ini system reboot` == "yes" ]] ; then
    echo "System will reboot in:"
    CountDown "00:00:05"
    sleep 1s; shutdown -r now
fi
