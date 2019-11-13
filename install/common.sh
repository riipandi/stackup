#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
NOCOLOR='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;33m'
BLUE='\033[0;34m'
CURRENT=$(dirname $(readlink -f $0))
[ -z $ROOTDIR ] && PWD=$(dirname $CURRENT) || PWD=$ROOTDIR

#----------------------------------------------------------------------------------
# StackUp installation script.
#----------------------------------------------------------------------------------

echo -e "${BLUE}\nCurrent server hostname is: ${RED}$(hostname -f)\n${NOCOLOR}"

# Server hostname
read -ep "Change server hostname?                     y/n : " -i "n" answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Enter server hostname                           : " -i "$(hostname -f)" answer
    hostnamectl set-hostname $answer
fi

# Create new user
#-----------------------------------------------------------------------------------------
createNewUser() {
    while true; do
        read -ep "Enter username for this user                    : " -i "admin" username
        read -ep "Enter new user real name                        : " -i "${username^}" fullname
        egrep "^$username" /etc/passwd >/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${RED}User $username already exists!${NOCOLOR}"
        else
            while true; do
                read -sp "Enter password for new user                     : " password
                if [ "$password" == "" ]; then
                    echo -e "${RED}\nPlease enter user password!${NOCOLOR}"
                else
                    password="$password" && break && echo
                fi
            done
            # Create new user
            pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
            useradd -mg webmaster -s `which bash` $username -c "$fullname" -p $pass
            usermod -a -G sudo $username
            if [ $? -eq 0 ] ; then
                HOMEDIR=$(eval echo "~$username")
                mkdir -p $HOMEDIR/.ssh ; chmod 0700 $_
                touch $HOMEDIR/.ssh/id_rsa ; chmod 0600 $_
                touch $HOMEDIR/.ssh/id_rsa.pub ; chmod 0600 $_
                touch $HOMEDIR/.ssh/authorized_keys ; chmod 0600 $_
                chown -R $username: $HOMEDIR/.ssh

                echo
                read -ep "Configure development environment?          y/n : " -i "y" answer
                if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
                    # Composer environment
                    if [ -x "$(command -v composer)" ]; then
                        echo -e "${BLUE}\nConfiguring Composer environment..${NOCOLOR}"
                        runuser -l $username -c 'composer global require hirak/prestissimo --quiet'
                        if ! grep -q 'composer' /home/$username/.bashrc ; then
                            echo 'export PATH=$PATH:$HOME/.config/composer/vendor/bin' >> "/home/$username/.bashrc"
                        fi
                    fi

                    # NodeJS environment
                    if [ -x "$(command -v yarn)" ]; then
                        echo -e "${BLUE}\nConfiguring NodeJS environment..${NOCOLOR}"
                        runuser -l $username -c 'sudo npm i -g ghost-cli@latest &>/dev/null'
                        if ! grep -q 'yarn' /home/$username/.bashrc ; then
                            echo 'export PATH=$PATH:$HOME/.yarn/bin' >> "/home/$username/.bashrc"
                        fi
                    fi
                fi

                echo -e "${BLUE}\nUser ${RED}$username${NOCOLOR} ${BLUE}has been added to system!${NOCOLOR}"
            else
                echo -e "${RED}Failed to add a user!${NOCOLOR}"
            fi
            break
        fi
    done
}

[[ $(cat /etc/group | grep -c webmaster) -eq 1 ]] || groupadd -g 3000 webmaster
read -ep "Create new system user?                     y/n : " -i "n" answer
[[ "${answer,,}" =~ ^(yes|y)$ ]] && createNewUser
