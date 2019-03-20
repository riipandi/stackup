#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

ROOT=$(dirname "$(readlink -f "$0")")

NO='\033[0;33m'
OK='\033[0;32m'
NC='\033[0m'

# Disable some motd banner
#-----------------------------------------------------------------------------------------
sudo chmod -x /etc/update-motd.d/10-help-text
sudo chmod -x /etc/update-motd.d/50-motd-news
sudo chmod -x /etc/update-motd.d/80-livepatch
sudo chmod -x /etc/update-motd.d/90-updates-available

# Some functions
#-----------------------------------------------------------------------------------------
CallScript() {
    source $ROOT/$1
}

InstallPackage() {
    [[ $(crudini --get $ROOT/config.ini $1 $2) != "yes" ]] || CallScript $3
}

# Initial setup
#-----------------------------------------------------------------------------------------
if [ $(crudini --get $ROOT/config.ini setup ready) != "yes" ]; then
    source "$ROOT/wizard.sh"
fi

# Request for create new user if not any sudoer
#-----------------------------------------------------------------------------------------
[[ $(cat /etc/passwd | grep -c "1101") -eq 1 ]] || bash $ROOT/snippets/create-sudoer 1101

# Preparing for installation
#-----------------------------------------------------------------------------------------
echo ; read -p "Press enter to begin installation..."

COUNTRY=`crudini --get $ROOT/config.ini system country`
if [ $COUNTRY == "ID" ] ; then
    cat $ROOT/repository/sources-id.list > /etc/apt/sources.list
elif [ $COUNTRY == "SG" ] ; then
    cat $ROOT/repository/sources-sg.list > /etc/apt/sources.list
else
    cat $ROOT/repository/sources.list > /etc/apt/sources.list
fi
sed -i "s/CODENAME/$(lsb_release -cs)/" /etc/apt/sources.list
apt update ; apt full-upgrade -y ; apt autoremove -y

# Preparing for installation
#-----------------------------------------------------------------------------------------
echo -e "\nInstalling basic packages..."
apt install -y sudo nano figlet elinks pwgen curl lsof whois dirmngr gnupg \
gcc make cmake build-essential software-properties-common debconf-utils \
apt-transport-https perl binutils dnsutils nscd ftp zip unzip bsdtar pv \
dh-autoreconf rsync screen screenfetch ca-certificates resolvconf nmap \
nikto speedtest-cli xmlstarlet optipng jpegoptim sqlite3 s3cmd virtualenv \
libpython2.7 {libpython,libpython2.7,python2.7}-dev python-virtualenv \
python3-virtualenv

# Copy snippets to local bin
cp $ROOT/snippets/* /usr/local/bin/
chown -R root: /usr/local/bin/*
chmod a+x /usr/local/bin/*

# Install and configure packages
#-----------------------------------------------------------------------------------------
InstallPackage 'system' 'swap_enable' 'system/swap-memory.sh'

CallScript 'system/set-openssh.sh'
CallScript 'system/set-network.sh'

CallScript 'nginx/setup.sh'
CallScript 'nginx/config.sh'

CallScript 'interpreter/setup-php.sh'
CallScript 'interpreter/setup-python.sh'
InstallPackage 'nodejs' 'install' 'interpreter/setup-nodejs.sh'

InstallPackage 'redis' 'install' 'database/redis-server.sh'

CallScript 'database/setup.sh'

# Set user environment for user with uid 1101.
#-----------------------------------------------------------------------------------------
ADMIN=`id -nu 1101`
runuser -l $ADMIN -c 'composer global require hirak/prestissimo laravel/installer wp-cli/wp-cli'
runuser -l $ADMIN -c 'yarn global add ghost-cli@latest'
if ! grep -q 'composer' /home/$ADMIN/.bashrc ; then
    echo 'export PATH=$PATH:$HOME/.config/composer/vendor/bin:$HOME/.yarn/bin' >> "/home/$ADMIN/.bashrc"
fi
mkdir -p /home/$ADMIN/.ssh ; chmod 0700 $_
touch /home/$ADMIN/.ssh/id_rsa ; chmod 0600 $_
touch /home/$ADMIN/.ssh/id_rsa.pub ; chmod 0600 $_
touch /home/$ADMIN/.ssh/authorized_keys ; chmod 0600 $_
chown -R $ADMIN: /home/$ADMIN/.ssh

# Cleanup and save some important information
#-----------------------------------------------------------------------------------------
echo -e "\nCleaning up installation...\n"
apt -y autoremove && apt clean && netstat -pltn

# Change root password and ask for creating deployer bot user
#-----------------------------------------------------------------------------------------
read -ep "Create user for deployer?    [Y/n] : " CreateUserDeployer
[[ ! "${CreateUserDeployer,,}" =~ ^(yes|y)$ ]] || CallScript 'snippets/create-buddy'

while true; do
    echo
    read -sp "Enter new password for root        : " NewRootPass
    if [[ $NewRootPass == "" ]]; then
        echo -e "${NO}Please enter new root password!${NC}"
    else
        usermod root --password $(perl -e 'print crypt($ARGV[0], "password")' $NewRootPass)
        if [ $? -eq 0 ] ; then
            echo -e "\n${OK}Password for root has beeen changed!${NC}"
        else
            echo -e "\n${NO}Failed to add a user!${NC}"
        fi
        break
    fi
done

# Save encrypted server information
INFO_FILE="/usr/local/etc/server-info.txt"
touch $INFO_FILE
{
    echo -e "MySQL root user : $(crudini --get $ROOT/config.ini mysql root_user)"
    echo -e "MySQL root pass : $(crudini --get $ROOT/config.ini mysql root_pass)\n"
    echo -e "PgSQL root user : $(crudini --get $ROOT/config.ini postgres root_user)"
    echo -e "PgSQL root pass : $(crudini --get $ROOT/config.ini postgres root_pass)"
} > $INFO_FILE

gpg --yes --batch --passphrase="$NewRootPass" -c $INFO_FILE
rm $INFO_FILE

echo -e "\nCongratulation, server stack has been installed."
echo -e "Server information located at: ${NO}${INFO_FILE}.gpg${NC}"
echo -e "\nThat file ${OK}encrypted${NC} with root user password."
echo -e "To see the decrypted file use this command:"
echo -e "\n${NO}gpg -d ${INFO_FILE}.gpg${NC}"
echo -e "\nAnd then enter your root password!\n"

# Reboot server if defined
if [[ `crudini --get $ROOT/config.ini system reboot` == "yes" ]] ; then
    echo "System will reboot in 5 seconds..."
    sleep 5s; shutdown -r now
fi
