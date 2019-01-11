#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

NO='\033[0;33m'
OK='\033[0;32m'
NC='\033[0m'

while true; do
    read -ep "Enter username for this user       : " -i "admin" username
    read -ep "Enter new user real name          : " -i "Admin Sistem" fullname
    egrep "^$username" /etc/passwd >/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${NO}User $username already exists!${NC}"
    else
        while true; do
            read -sp "Enter password for new user       : " password
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
            echo -e "${OK}\nUser ${NO}$username${NC} ${OK}has been added to system!${NC}"
        else
            echo -e "${NO}Failed to add a user!${NC}"
        fi
        break
    fi
done
