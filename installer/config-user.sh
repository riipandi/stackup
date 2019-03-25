#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
NO='\033[0;33m' ; OK='\033[0;32m' ; NC='\033[0m'
#------------------------------------------------------------------------------

read -ep "Create new sudo user?                       y/n : " -i "y" answer

if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    echo
    while true; do
        read -ep "Enter username for this user                    : " -i "admin" username
        read -ep "Enter new user real name                        : " -i "Admin Sistem" fullname
        egrep "^$username" /etc/passwd >/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${NO}User $username already exists!${NC}"
        else
            while true; do
                read -sp "Enter password for new user                     : " password
                if [ "$password" == "" ]; then
                    echo -e "${NO}\nPlease enter user password!${NC}"
                else
                    password="$password" && break && echo
                fi
            done
            # Create new user
            pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
            useradd -mg sudo -s `which bash` $username -c "$fullname" -p $pass
            if [ $? -eq 0 ] ; then
                HOMEDIR=$(eval echo "~$username")
                mkdir -p $HOMEDIR/.ssh ; chmod 0700 $_
                touch $HOMEDIR/.ssh/id_rsa ; chmod 0600 $_
                touch $HOMEDIR/.ssh/id_rsa.pub ; chmod 0600 $_
                touch $HOMEDIR/.ssh/authorized_keys ; chmod 0600 $_
                chown -R $username: $HOMEDIR/.ssh

                echo
                read -ep "Configure development environment?          y/n : " answer
                if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
                    # Composer environment
                    if [ -x "$(command -v composer)" ]; then
                        echo -e "${OK}\nConfiguring Composer environment..${NC}"
                        runuser -l $username -c 'composer global require hirak/prestissimo laravel/installer wp-cli/wp-cli'
                        if ! grep -q 'composer' /home/$username/.bashrc ; then
                            echo 'export PATH=$PATH:$HOME/.config/composer/vendor/bin' >> "/home/$username/.bashrc"
                        fi
                    fi

                    # NodeJS environment
                    if [ -x "$(command -v yarn)" ]; then
                        echo -e "${OK}\nConfiguring NodeJS environment..${NC}"
                        runuser -l $username -c 'sudo npm i -g ghost-cli@latest'
                        if ! grep -q 'composer' /home/$username/.bashrc ; then
                            echo 'export PATH=$PATH:$HOME/.yarn/bin' >> "/home/$username/.bashrc"
                        fi
                    fi
                fi

                echo -e "${OK}\nUser ${NO}$username${NC} ${OK}has been added to system!${NC}"
            else
                echo -e "${NO}Failed to add a user!${NC}"
            fi
            break
        fi
    done
fi
