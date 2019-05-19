#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
ROOT=$(dirname "$(readlink -f "$0")")
#------------------------------------------------------------------------------
# StackUp Installation Script.
#------------------------------------------------------------------------------

# Set working directory
WORKDIR=/usr/src/stackup

# Check OS support
distr=`echo $(lsb_release -i | cut -d':' -f 2)`
osver=`echo $(lsb_release -c | cut -d':' -f 2)`
if ! [[ $distr == "Ubuntu" && $osver =~ ^(xenial|bionic)$ ]]; then
    echo "$(tput setaf 1)"
    echo "**************************************************************"
    echo "****   This OS distribution is not supported by StackUp   ****"
    echo "**************************************************************"
    echo "$(tput sgr0)"
    exit 1
else
    read -p "Press [Enter] to Continue or [Ctrl+C] to Cancel..."
fi

# Install required dependencies
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Installing required dependencies...${NC}"
cat > /etc/apt/apt.conf.d/99force-config <<EOF
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
}
EOF
apt update -qq ; apt -y full-upgrade
apt -yqq install git curl crudini openssl figlet perl python-click
apt -y autoremove

# Clone setup file and begin instalation process
#-----------------------------------------------------------------------------------------
if [ ! -z "$1" ] && [ "$1" == "--dev" ]; then CHANNEL="dev" ; else CHANNEL="stable" ; fi
[[ ! -d $WORKDIR ]] || rm -fr $WORKDIR && rm -fr /tmp/stackup-*

if [ $CHANNEL == "dev" ]; then
    git clone https://github.com/riipandi/stackup $WORKDIR
else
    project="https://api.github.com/repos/riipandi/stackup/releases/latest"
    release=`curl -s $project | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`
    curl -fsSL https://github.com/riipandi/stackup/archive/$release.zip | bsdtar -xvf- -C /tmp
    version=`echo "${release/v/}"` ; mv /tmp/stackup-$version $WORKDIR
fi

find $WORKDIR/ -type f -name '*.py' -exec chmod +x {} \;
find $WORKDIR/ -type f -name '*.sh' -exec chmod +x {} \;
find $WORKDIR/ -type f -name '.git*' -exec rm -fr {} \;
rm -fr /etc/apt/sources.list.d/*

# Begin installation process
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Starting StackUp installer...\n${NC}"
read -p "Press [Enter] to Continue or [Ctrl+C] to Cancel..."
chmod +x $WORKDIR/snippet/* && cp $WORKDIR/snippet/* /usr/local/bin/.

echo
read -ep "Enter server hostname                           : " -i "$(hostname -f)" server_hostname
hostnamectl set-hostname $server_hostname

crudini --set $WORKDIR/stackup.ini '' 'setup_ready' 'no'
bash "$WORKDIR/installer/wizard.sh"
bash "$WORKDIR/installer/common.sh"

# Install MySQL / MariaDB
#-----------------------------------------------------------------------------------------
mysql_install=$(crudini --get $PWD/stackup.ini '' 'mysql_install')
if [[ "${mysql_install,,}" =~ ^(yes|y)$ ]] ; then
    mysql_engine=$(crudini --get $PWD/stackup.ini '' 'mysql_engine')
    if [[ "$mysql_engine" == "mysql" ]] ; then
        bash "$WORKDIR/installer/setup-mysql.sh"
    else
        bash "$WORKDIR/installer/setup-mariadb.sh"
    fi
    bash "$WORKDIR/installer/tools-pma.sh"
fi

# Install PostgreSQL
#-----------------------------------------------------------------------------------------
pgsql_install=$(crudini --get $PWD/stackup.ini '' 'pgsql_install')
if [[ "${pgsql_install,,}" =~ ^(yes|y)$ ]] ; then
    bash "$WORKDIR/installer/setup-pgsql.sh"
    bash "$WORKDIR/installer/tools-pgadmin4.sh"
fi

# Install Redis Server
#-----------------------------------------------------------------------------------------
redis_install=$(crudini --get $PWD/stackup.ini '' 'redis_install')
[[ "${redis_install,,}" =~ ^(yes|y)$ ]] && bash "$WORKDIR/installer/setup-redis.sh"

# Install NodeJS and Yarn
#-----------------------------------------------------------------------------------------
nodejs_install=$(crudini --get $PWD/stackup.ini '' 'nodejs_install')
[[ "${nodejs_install,,}" =~ ^(yes|y)$ ]] && bash "$WORKDIR/installer/setup-nodejs.sh"

# Install Nginx + PHP-FPM
#-----------------------------------------------------------------------------------------
bash "$WORKDIR/installer/setup-php.sh"
bash "$WORKDIR/installer/setup-nginx.sh"

# Telegram SSH Notification
#-----------------------------------------------------------------------------------------
tgnotif_install=$(crudini --get $WORKDIR/stackup.ini '' 'tgnotif_install')
if [[ "${tgnotif_install,,}" =~ ^(yes|y)$ ]] ; then
    sed -i "s/VAR_BOTKEY/$(crudini --get $WORKDIR/stackup.ini '' 'tgnotif_bot_key')/" $WORKDIR/stubs/tg-notif.sh
    sed -i "s/VAR_CHATID/$(crudini --get $WORKDIR/stackup.ini '' 'tgnotif_chat_id')/" $WORKDIR/stubs/tg-notif.sh
    cp $WORKDIR/stubs/tg-notif.sh /etc/profile.d/ ; chmod +x $_
fi

# Create new user
#-----------------------------------------------------------------------------------------
read -ep "Create new system user?                     y/n : " -i "y" answer
[[ "${answer,,}" =~ ^(yes|y)$ ]] && bash "/usr/local/bin/create-user"

# Cleanup and save some important information
#-----------------------------------------------------------------------------------------
echo -e "\n${OK}Cleaning up installation...${NC}\n"
apt -y autoremove && apt clean && echo && netstat -pltn
echo -e "\n${OK}Installation has been finish...${NC}\n"
