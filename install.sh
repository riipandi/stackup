#!/usr/bin/env bash

ROOT=$(dirname "$(readlink -f "$0")")

# Check if this script running as root
if [[ $EUID -ne 0 ]]; then
    echo -e 'This script must be run as root' ; exit 1
else
    read -p "Press enter to continue ..."
fi

SetConfigSetup() {
    crudini --set $ROOT/config.ini $1 $2 $3
}

GetConfigSetup() {
    crudini --get $ROOT/config.ini $1 $2
}

InstallPackage() {
    if [ `crudini --get $ROOT/config.ini $1 $2` == "yes" ]; then
        source $3
    fi
}

countdown()
(
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

# Change default repository mirror
read -ep "Change repository mirror?  yes/no : " -i "yes" changrepo
if [[ "${changrepo,,}" =~ ^(yes|y)$ ]] ; then source $ROOT/system/repository.sh ; fi

ChangeRootPass() {
    read -sp "Enter new root password           : " rootpass
    if [[ "$rootpass" == "" ]] ; then
        echo -e "" && ChangeRootPass
    else
        usermod root --password `openssl passwd -1 "$rootpass"`
    fi
}
read -ep "Change root password?      yes/no : " -i "no" changerootpass
if [[ "${changerootpass,,}" =~ ^(yes|y)$ ]] ; then ChangeRootPass ; fi

CreateNewUser() {
    while true; do
        echo
        read -sp "Enter new user password           : " userpass1
        [ "$userpass1" == "" ] && CreateNewUser
        echo
        read -sp "Enter new user password (again)   : " userpass2
        [ "$userpass1" = "$userpass2" ] && break
    done
    useradd -mg sudo -s `which bash` $username -c "$fullname" -p `openssl passwd -1 "$userpass1"`
    echo
}

read -ep "Create a new user?         yes/no : " -i "yes" createuser
if [[ "${createuser,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Enter new user fullname           : " -i "Admin Sistem" fullname
    read -ep "Enter new user username           : " -i "admin" username
    CreateNewUser
fi

# Upgrade basic system packages
source $ROOT/system/basicpkg.sh

# Determine country code for server location
country=`curl -s ipinfo.io | grep country | awk -F":" '{print $2}' | cut -d '"' -f2`
crudini --set $ROOT/config.ini 'system' 'country' $country

# Print welcome message
figlet "Are you ready?"
read -p "Press enter to continue ..."

#-----------------------------------------------------------------------------------------
# System and packages setup
#-----------------------------------------------------------------------------------------
read -ep "Please specify SSH port          : " -i "22" ssh_port
SetConfigSetup system ssh_port $ssh_port

read -ep "Please specify time zone         : " -i "Asia/Jakarta" timezone
SetConfigSetup system timezone $timezone

read -ep "Disable IPv6              yes/no : " -i "no" disable_ipv6
SetConfigSetup system disable_ipv6 $disable_ipv6

read -ep "Use Telegram Notif        yes/no : " -i "no" tgnotif_install
SetConfigSetup tgnotif install $tgnotif_install
if [[ "${tgnotif_install,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Telegram Bot Key                 : " -i "" tgnotif_bot_key
    SetConfigSetup tgnotif bot_key $tgnotif_bot_key
    read -ep "Telegram User Chat ID            : " -i "" tgnotif_chat_id
    SetConfigSetup tgnotif chat_id $tgnotif_chat_id
fi

read -ep "Install Nginx Amplify     yes/no : " -i "no" amplify_install
SetConfigSetup nginx amplify $amplify_install
if [[ "${amplify_install,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Nginx Amplify API Key            : " -i "" amplify_api
    SetConfigSetup nginx api_key $amplify_api
fi

read -ep "Database Engine  (mariadb/mysql) : " -i "mariadb" db_engine
SetConfigSetup mysql engine $db_engine
read -ep "Database Bind Address            : " -i "127.0.0.1" bind_address
SetConfigSetup mysql bind_address $bind_address
read -ep "Database Root Password           : "  -i "auto" root_pass
if [[ "$root_pass" == "auto" ]] ; then
    SetConfigSetup mysql root_pass `pwgen -1 12`
else
    SetConfigSetup mysql root_pass $root_pass
fi

read -ep "Install PostgreSQL        yes/no : " -i "no" pgsql_install
SetConfigSetup postgres install $pgsql_install
if [[ "${pgsql_install,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "PostgreSQL Root Password         : "  -i "auto" root_pass
    if [[ "$root_pass" == "auto" ]] ; then
        SetConfigSetup postgres root_pass `pwgen -1 12`
    else
        SetConfigSetup postgres root_pass $root_pass
    fi
fi

read -ep "Install Redis Server      yes/no : " -i "yes" redis_install
SetConfigSetup redis install $redis_install

if [[ "${redis_install,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Redis Server Password            : "  -i "" redispass
    if [[ "$redispass" != "" ]] ; then
        SetConfigSetup redis password $redispass
    fi
fi

read -ep "Install NodeJS and Yarn   yes/no : " -i "yes" nodejs_install
SetConfigSetup extras nodejs $nodejs_install

## Setup PHP repo
echo "deb https://packages.sury.org/php/ `lsb_release -cs` main" > /etc/apt/sources.list.d/sury-php.list
curl -sS https://packages.sury.org/php/apt.gpg | apt-key add -

read -ep "Install PHP 5.6           yes/no : " -i "yes" php56_install
SetConfigSetup php php56 $php56_install

read -ep "Install PHP 7.2           yes/no : " -i "yes" php72_install
SetConfigSetup php php72 $php72_install

read -ep "Install PHP 7.3           yes/no : " -i "no" php73_install
SetConfigSetup php php73 $php73_install

read -ep "Default PHP ver?   (5.6/7.2/7.3) : " -i "7.2" php_default
SetConfigSetup php default $php_default

read -ep "Install python            yes/no : " -i "no" python_install
SetConfigSetup extras python $python_install

read -ep "Install IMAPSync          yes/no : " -i "yes" imapsync_install
SetConfigSetup extras imapsync $imapsync_install

read -ep "Install PowerDNS          yes/no : " -i "no" powerdns_install
SetConfigSetup powerdns install $powerdns_install

read -ep "Install FTP Server        yes/no : " -i "no" ftpserver_install
SetConfigSetup ftpserver install $powerdns_install

read -ep "Install Mail Server       yes/no : " -i "no" mailserver_install
SetConfigSetup mailserver install $powerdns_install

# Determine total memory
memoryTotal=`grep MemTotal /proc/meminfo | awk '{print $2}'`
if (( $memoryTotal >= 2097152 )); then opsi="no"; else opsi="yes";fi

read -ep "Do you want to use Swap   yes/no : " -i "$opsi" swap_enable
SetConfigSetup swap enable $swap_enable
if [[ "${enabled,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Size of Swap (in megabyte)       : "  -i "2048" swap_size
    SetConfigSetup swap size $swap_size
fi

read -ep "Reboot after install      yes/no : " -i "no" reboot_after
SetConfigSetup system reboot $reboot_after

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
cp $ROOT/snippets/fix-permission /usr/local/bin/fix-permission ; chmod +x $_
cp $ROOT/snippets/mysql-create /usr/local/bin/mysql-create ; chmod +x $_
cp $ROOT/snippets/vhost-create /usr/local/bin/vhost-create ; chmod +x $_
cp $ROOT/snippets/ssl-revoke /usr/local/bin/ssl-revoke ; chmod +x $_
cp $ROOT/snippets/ssl-create /usr/local/bin/ssl-create ; chmod +x $_
cp $ROOT/snippets/ssl-wildcard /usr/local/bin/ssl-wildcard ; chmod +x $_

cp $ROOT/php/configure.sh /usr/local/bin/set-php ; chmod +x $_

# Fix permission for snippets
chmod a+x /usr/local/bin/* ; chown -R root: /usr/local/bin/*

echo "" && apt -y autoremove && apt clean && netstat -pltn

echo -e "\nCongratulation, server stack has been installed.\n"

if [[ `crudini --get $ROOT/config.ini system reboot` == "yes" ]] ; then
    echo "System will reboot in:"
    countdown "00:00:05" ; shutdown -r now
fi
